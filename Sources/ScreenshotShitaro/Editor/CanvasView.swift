import AppKit
import Observation

/// 注釈キャンバス NSView
/// - 背景にスクリーンショット画像を表示
/// - マウスドラッグで注釈を追加
/// - AnnotationStore を監視して全注釈を再描画
@MainActor
final class CanvasView: NSView {

    // MARK: - Properties

    private let backgroundImage: NSImage
    private let store: AnnotationStore

    /// 現在選択中のツール（ToolbarView から設定される）
    var currentTool: AnnotationTool = .arrow

    /// 現在の描画スタイル
    var currentStyle: AnnotationStyle = AnnotationStyle()

    // ドラッグ中の始点・現在点
    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?

    // テキストオーバーレイ
    private var textOverlay: TextInputOverlay?

    // MARK: - Init

    init(image: NSImage, store: AnnotationStore) {
        self.backgroundImage = image
        self.store = store
        super.init(frame: .zero)
        observeStore()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未サポートです")
    }

    // MARK: - Coordinate system（上がオリジン、y 下向き = 画像座標と一致）

    override var isFlipped: Bool { true }

    // MARK: - Observation

    private func observeStore() {
        withObservationTracking {
            _ = store.annotations.count
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.needsDisplay = true
                self?.observeStore()  // 変更後に再登録
            }
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // 背景クリア
        NSColor.darkGray.setFill()
        bounds.fill()

        // 背景画像をアスペクト比を保ちつつ描画
        let imageRect = fitRect(for: backgroundImage.size, in: bounds)
        backgroundImage.draw(in: imageRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let bgCGImage = backgroundImage.cgImage(
            forProposedRect: nil,
            context: NSGraphicsContext.current,
            hints: nil
        )

        // 確定済み注釈を描画
        for annotation in store.annotations {
            AnnotationRenderer.draw(
                annotation,
                in: context,
                backgroundImage: bgCGImage,
                imageRect: imageRect,
                isDraft: false
            )
        }

        // ドラッグ中の仮注釈を描画
        if let start = dragStart, let current = dragCurrent,
           let inProgress = makeAnnotation(from: start, to: current) {
            AnnotationRenderer.draw(
                inProgress,
                in: context,
                backgroundImage: bgCGImage,
                imageRect: imageRect,
                isDraft: true
            )
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if currentTool == .text {
            showTextOverlay(at: point)
        } else {
            dragStart = point
            dragCurrent = point
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard currentTool != .text else { return }
        dragCurrent = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard currentTool != .text,
              let start = dragStart,
              let end = dragCurrent else {
            dragStart = nil
            dragCurrent = nil
            return
        }
        if let annotation = makeAnnotation(from: start, to: end) {
            store.add(annotation)
        }
        dragStart = nil
        dragCurrent = nil
        needsDisplay = true
    }

    // MARK: - Keyboard（Undo / Redo）

    override var acceptsFirstResponder: Bool { true }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        switch event.charactersIgnoringModifiers {
        case "z":
            if event.modifierFlags.contains(.shift) {
                store.redo()
            } else {
                store.undo()
            }
            needsDisplay = true
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    // MARK: - Annotation Factory

    private func makeAnnotation(from start: CGPoint, to end: CGPoint) -> Annotation? {
        switch currentTool {
        case .arrow:
            return .arrow(start: start, end: end, style: currentStyle)
        case .rect:
            return .rect(frame: .init(from: start, to: end), style: currentStyle)
        case .circle:
            return .circle(frame: .init(from: start, to: end), style: currentStyle)
        case .line:
            return .line(start: start, end: end, style: currentStyle)
        case .text:
            return nil  // TextInputOverlay 経由で追加
        case .blur:
            return .blur(frame: .init(from: start, to: end))
        case .highlight:
            return .highlight(frame: .init(from: start, to: end), style: currentStyle)
        }
    }

    // MARK: - Layout Helpers

    /// アスペクト比を保ちながら画像をビュー内に収める矩形（letter-box）
    private func fitRect(for imageSize: CGSize, in viewBounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return viewBounds }
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewBounds.width / viewBounds.height
        let drawSize: CGSize
        if imageAspect > viewAspect {
            drawSize = CGSize(width: viewBounds.width, height: viewBounds.width / imageAspect)
        } else {
            drawSize = CGSize(width: viewBounds.height * imageAspect, height: viewBounds.height)
        }
        return CGRect(
            x: (viewBounds.width - drawSize.width) / 2,
            y: (viewBounds.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
    }

    // MARK: - Text Overlay

    private func showTextOverlay(at point: CGPoint) {
        textOverlay?.removeFromSuperview()
        let overlay = TextInputOverlay(origin: point, style: currentStyle) { [weak self] text in
            guard let self, !text.isEmpty else { return }
            self.store.add(.text(origin: point, content: text, style: self.currentStyle))
            self.needsDisplay = true
        }
        addSubview(overlay)
        overlay.activate()
        textOverlay = overlay
    }
}

// MARK: - CGRect Helper

private extension CGRect {
    /// 2点から正規化済み矩形を生成
    init(from p1: CGPoint, to p2: CGPoint) {
        self.init(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }
}
