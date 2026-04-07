import AppKit
import CoreImage

/// 各 Annotation を CGContext に描画する純粋関数群
enum AnnotationRenderer {

    /// アノテーションを描画する
    /// - Parameters:
    ///   - annotation: 描画対象
    ///   - context: 描画先 CGContext（NSView の draw(_:) 内で取得）
    ///   - backgroundImage: ぼかし処理に使う背景 CGImage（blur のみ参照）
    ///   - imageRect: ビュー内で背景画像が描かれている矩形（ぼかし座標変換に使用）
    ///   - isDraft: ドラッグ中の中間描画かどうか（true の場合 blur をプレースホルダーで描画）
    static func draw(
        _ annotation: Annotation,
        in context: CGContext,
        backgroundImage: CGImage? = nil,
        imageRect: CGRect = .zero,
        isDraft: Bool = false
    ) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        switch annotation {
        case .arrow(let start, let end, let style):
            drawArrow(from: start, to: end, style: style)
        case .rect(let frame, let style):
            drawRect(frame: frame, style: style)
        case .circle(let frame, let style):
            drawCircle(frame: frame, style: style)
        case .line(let start, let end, let style):
            drawLine(from: start, to: end, style: style)
        case .text(let origin, let content, let style):
            drawText(at: origin, content: content, style: style)
        case .blur(let frame):
            if isDraft || backgroundImage == nil {
                drawBlurPlaceholder(frame: frame)
            } else {
                drawBlur(frame: frame, backgroundImage: backgroundImage!, imageRect: imageRect)
            }
        case .highlight(let frame, let style):
            drawHighlight(frame: frame, style: style)
        }
    }

    // MARK: - Arrow

    private static func drawArrow(from start: CGPoint, to end: CGPoint, style: AnnotationStyle) {
        guard start != end else { return }

        // draw() のたびに atan2 で角度を再計算（形崩れ防止）
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(style.lineWidth * 4, 12)
        let headAngle: CGFloat = .pi / 6  // 30°

        // シャフト
        let shaft = NSBezierPath()
        shaft.move(to: start)
        // シャフトは矢印頭の付け根まで
        let shaftEnd = CGPoint(
            x: end.x - headLength * 0.7 * cos(angle),
            y: end.y - headLength * 0.7 * sin(angle)
        )
        shaft.line(to: shaftEnd)
        shaft.lineWidth = style.lineWidth
        shaft.lineCapStyle = .round
        style.color.setStroke()
        shaft.stroke()

        // 矢印頭（塗りつぶし三角形）
        let head = NSBezierPath()
        head.move(to: end)
        head.line(to: CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        ))
        head.line(to: CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        ))
        head.close()
        style.color.setFill()
        head.fill()
    }

    // MARK: - Rect

    private static func drawRect(frame: CGRect, style: AnnotationStyle) {
        guard frame.width > 0, frame.height > 0 else { return }
        let path = NSBezierPath(rect: frame)
        path.lineWidth = style.lineWidth
        style.color.setStroke()
        path.stroke()
    }

    // MARK: - Circle

    private static func drawCircle(frame: CGRect, style: AnnotationStyle) {
        guard frame.width > 0, frame.height > 0 else { return }
        let path = NSBezierPath(ovalIn: frame)
        path.lineWidth = style.lineWidth
        style.color.setStroke()
        path.stroke()
    }

    // MARK: - Line

    private static func drawLine(from start: CGPoint, to end: CGPoint, style: AnnotationStyle) {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        path.lineWidth = style.lineWidth
        path.lineCapStyle = .round
        style.color.setStroke()
        path.stroke()
    }

    // MARK: - Text

    private static func drawText(at origin: CGPoint, content: String, style: AnnotationStyle) {
        guard !content.isEmpty else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: style.fontSize),
            .foregroundColor: style.color
        ]
        NSAttributedString(string: content, attributes: attrs).draw(at: origin)
    }

    // MARK: - Blur

    /// ドラッグ中または背景画像未取得時のプレースホルダー
    private static func drawBlurPlaceholder(frame: CGRect) {
        guard frame.width > 0, frame.height > 0 else { return }
        let path = NSBezierPath(rect: frame)
        NSColor.systemGray.withAlphaComponent(0.25).setFill()
        path.fill()
        path.lineWidth = 1.5
        NSColor.systemGray.setStroke()
        let dash: [CGFloat] = [4, 4]
        path.setLineDash(dash, count: 2, phase: 0)
        path.stroke()
    }

    /// 背景画像の指定領域をぼかして描画する
    private static func drawBlur(frame: CGRect, backgroundImage: CGImage, imageRect: CGRect) {
        guard frame.width > 1, frame.height > 1,
              imageRect.width > 0, imageRect.height > 0 else {
            drawBlurPlaceholder(frame: frame)
            return
        }

        // ビュー座標（isFlipped=true, top-left origin）→ CGImage ピクセル座標（bottom-left origin）
        let scaleX = CGFloat(backgroundImage.width) / imageRect.width
        let scaleY = CGFloat(backgroundImage.height) / imageRect.height

        let pixX = (frame.minX - imageRect.minX) * scaleX
        let pixW = frame.width * scaleX
        let pixH = frame.height * scaleY
        // y軸反転（CGImage は非フリップ）
        let pixY = CGFloat(backgroundImage.height) - (frame.minY - imageRect.minY) * scaleY - pixH

        let pixRect = CGRect(x: pixX, y: pixY, width: pixW, height: pixH)

        // CGImage から対象領域をクロップしてぼかし適用
        guard let cropped = backgroundImage.cropping(to: pixRect) else {
            drawBlurPlaceholder(frame: frame)
            return
        }

        let ciImage = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            drawBlurPlaceholder(frame: frame)
            return
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(12.0, forKey: kCIInputRadiusKey)

        let ciContext = CIContext(options: [.useSoftwareRenderer: false])
        guard let output = filter.outputImage,
              let blurredCG = ciContext.createCGImage(output, from: ciImage.extent) else {
            drawBlurPlaceholder(frame: frame)
            return
        }

        // ぼかし済み画像をビュー座標の frame に描画
        NSImage(cgImage: blurredCG, size: frame.size).draw(in: frame)
    }

    // MARK: - Highlight

    private static func drawHighlight(frame: CGRect, style: AnnotationStyle) {
        guard frame.width > 0, frame.height > 0 else { return }
        style.color.withAlphaComponent(0.35).setFill()
        NSBezierPath(rect: frame).fill()
    }
}
