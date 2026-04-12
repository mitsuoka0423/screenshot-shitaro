import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct EditorView: View {
    @Environment(\.undoManager) private var undoManager
    @Environment(ScreenshotDetector.self) private var detector

    @State private var store = AnnotationStore()
    @State private var previewAnnotation: Annotation?
    @State private var canvasSize: CGSize = CGSize(width: 800, height: 600)

    // テキストツール
    @State private var textInputPosition: CGPoint?
    @State private var textInput = ""

    // blur ツール: 事前処理済み CGImage
    @State private var blurredImages: [UUID: CGImage] = [:]

    // ソース画像（ScreenshotDetector.latestScreenshotURL から自動更新）
    @State private var sourceImage: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(store: store) {
                undoManager?.undo()
            } onRedo: {
                undoManager?.redo()
            }

            Divider()

            canvasArea
        }
        .frame(minWidth: 640, minHeight: 480)
        // ⌘+C / ⌘+S は非表示ボタン経由でウィンドウ全体に効かせる
        .background(keyboardShortcutButtons)
        .onAppear {
            // AppKit 使用: floating ウィンドウ設定（1行のみ）
            NSApp.windows.first { $0.title == "Editor" }?.level = .floating
        }
        // 新しいスクリーンショットが検知されたら画像を読み込みキャンバスをリセット
        .onChange(of: detector.latestScreenshotURL) { _, url in
            guard let url else { return }
            sourceImage = NSImage(contentsOf: url)
            store.removeAll()
            blurredImages.removeAll()
        }
    }

    // MARK: - Canvas エリア

    @ViewBuilder
    private var canvasArea: some View {
        ZStack {
            // 背景：ソース画像またはプレースホルダー
            Group {
                if let img = sourceImage {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color(white: 0.14)
                        .overlay {
                            Text("スクリーンショットを取得してください")
                                .foregroundStyle(.secondary)
                        }
                }
            }

            // アノテーション Canvas
            let annotations = store.annotations
            let preview = previewAnnotation
            let blurImgs = blurredImages

            Canvas { context, size in
                for annotation in annotations {
                    AnnotationRenderer.draw(annotation, blurredImages: blurImgs, in: &context)
                }
                if let p = preview {
                    AnnotationRenderer.draw(p, blurredImages: [:], in: &context, alpha: 0.6)
                }
            }
            .gesture(dragGesture)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { canvasSize = geo.size }
                        .onChange(of: geo.size) { _, s in canvasSize = s }
                }
            }

            // テキスト入力オーバーレイ
            if let pos = textInputPosition {
                TextField("テキスト入力", text: $textInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(store.strokeColor)
                    .frame(minWidth: 140)
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .position(pos)
                    .onSubmit { commitText(at: pos) }
            }
        }
    }

    // MARK: - DragGesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let start = value.startLocation
                let current = value.location
                // 最小移動量以下はプレビューをまだ出さない
                let moved = hypot(value.translation.width, value.translation.height)
                guard moved > 2 || store.currentTool == .text else { return }
                previewAnnotation = buildAnnotation(start: start, end: current)
            }
            .onEnded { value in
                previewAnnotation = nil
                let annotation = buildAnnotation(start: value.startLocation, end: value.location)

                switch store.currentTool {
                case .text:
                    textInput = ""
                    textInputPosition = value.startLocation
                case .blur:
                    store.add(annotation, undoManager: undoManager)
                    Task {
                        await applyBlur(for: annotation)
                    }
                default:
                    store.add(annotation, undoManager: undoManager)
                }
            }
    }

    private func buildAnnotation(start: CGPoint, end: CGPoint) -> Annotation {
        let blurRect: CGRect? = store.currentTool == .blur
            ? CGRect(
                x: min(start.x, end.x), y: min(start.y, end.y),
                width: abs(end.x - start.x), height: abs(end.y - start.y)
              )
            : nil

        return Annotation(
            id: UUID(),
            tool: store.currentTool,
            start: start,
            end: end,
            color: store.strokeColor,
            lineWidth: store.lineWidth,
            text: nil,
            blurRect: blurRect
        )
    }

    // MARK: - テキスト確定

    private func commitText(at pos: CGPoint) {
        guard !textInput.isEmpty else {
            textInputPosition = nil
            return
        }
        let annotation = Annotation(
            id: UUID(),
            tool: .text,
            start: pos,
            end: pos,
            color: store.strokeColor,
            lineWidth: store.lineWidth,
            text: textInput,
            blurRect: nil
        )
        store.add(annotation, undoManager: undoManager)
        textInput = ""
        textInputPosition = nil
    }

    // MARK: - Blur 処理（async - Task 内から呼ぶ）

    @MainActor
    private func applyBlur(for annotation: Annotation) async {
        guard let rect = annotation.blurRect,
              let nsImg = sourceImage,
              let cgImage = nsImg.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return }

        if let blurred = await BlurProcessor.shared.blur(image: cgImage, rect: rect) {
            blurredImages[annotation.id] = blurred
        }
    }

    // MARK: - エクスポート

    private func renderToImage() -> NSImage? {
        let size = canvasSize
        let annotations = store.annotations
        let blurImgs = blurredImages
        let srcImg = sourceImage

        let view = ZStack {
            if let img = srcImg {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: size.width, height: size.height)
            } else {
                Color(white: 0.14)
                    .frame(width: size.width, height: size.height)
            }
            Canvas { context, _ in
                for annotation in annotations {
                    AnnotationRenderer.draw(annotation, blurredImages: blurImgs, in: &context)
                }
            }
            .frame(width: size.width, height: size.height)
        }

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.nsImage
    }

    // MARK: - ⌘+C (BUG-3: コピー後はウィンドウを閉じない)

    private func handleCopy() {
        guard let image = renderToImage() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        // ウィンドウは維持（BUG-3 対応 — close() は呼ばない）
    }

    // MARK: - ⌘+S

    private func handleSave() {
        guard let image = renderToImage(),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.png]
        panel.nameFieldStringValue = "screenshot.png"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? pngData.write(to: url)
        }
    }

    // MARK: - キーボードショートカット（非表示ボタン）

    private var keyboardShortcutButtons: some View {
        ZStack {
            Button("copy") { handleCopy() }
                .keyboardShortcut("c", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
            Button("save") { handleSave() }
                .keyboardShortcut("s", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
    }
}
