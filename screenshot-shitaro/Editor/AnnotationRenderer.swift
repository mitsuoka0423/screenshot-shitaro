import SwiftUI

/// 純粋 Swift の描画ロジック。Path を生成する static 関数群。
/// NSBezierPath は使用しない。
enum AnnotationRenderer {

    // MARK: - Path 生成

    /// 矢印パス（atan2 で矢印頭を計算）
    static func arrowPath(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat) -> Path {
        var path = Path()
        guard start != end else { return path }

        path.move(to: start)
        path.addLine(to: end)

        let headLength = max(lineWidth * 4, 14)
        let angle = atan2(end.y - start.y, end.x - start.x)
        let spread: CGFloat = .pi / 6 // 30°

        let tip1 = CGPoint(
            x: end.x - headLength * cos(angle - spread),
            y: end.y - headLength * sin(angle - spread)
        )
        let tip2 = CGPoint(
            x: end.x - headLength * cos(angle + spread),
            y: end.y - headLength * sin(angle + spread)
        )

        path.move(to: end)
        path.addLine(to: tip1)
        path.move(to: end)
        path.addLine(to: tip2)

        return path
    }

    /// 矩形パス
    static func rectPath(from start: CGPoint, to end: CGPoint) -> Path {
        Path(normalizedRect(from: start, to: end))
    }

    /// 楕円パス
    static func circlePath(from start: CGPoint, to end: CGPoint) -> Path {
        Path(ellipseIn: normalizedRect(from: start, to: end))
    }

    /// 直線パス
    static func linePath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    /// ハイライトパス（水平方向の帯）
    static func highlightPath(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat) -> Path {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y) - lineWidth / 2,
            width: abs(end.x - start.x),
            height: lineWidth
        )
        return Path(rect)
    }

    // MARK: - GraphicsContext 描画

    /// Annotation を GraphicsContext に描画する。
    /// - Parameters:
    ///   - annotation: 描画対象
    ///   - blurredImages: blur ツール用の事前処理済み CGImage（UUID → CGImage）
    ///   - context: Canvas の描画コンテキスト
    ///   - alpha: プレビュー時の透過度（デフォルト 1.0）
    static func draw(
        _ annotation: Annotation,
        blurredImages: [UUID: CGImage],
        in context: inout GraphicsContext,
        alpha: Double = 1.0
    ) {
        let color = annotation.color.opacity(alpha)

        switch annotation.tool {
        case .arrow:
            let path = arrowPath(from: annotation.start, to: annotation.end, lineWidth: annotation.lineWidth)
            context.stroke(path, with: .color(color), lineWidth: annotation.lineWidth)

        case .rect:
            let path = rectPath(from: annotation.start, to: annotation.end)
            context.stroke(path, with: .color(color), lineWidth: annotation.lineWidth)

        case .circle:
            let path = circlePath(from: annotation.start, to: annotation.end)
            context.stroke(path, with: .color(color), lineWidth: annotation.lineWidth)

        case .line:
            let path = linePath(from: annotation.start, to: annotation.end)
            context.stroke(path, with: .color(color), lineWidth: annotation.lineWidth)

        case .highlight:
            let path = highlightPath(from: annotation.start, to: annotation.end, lineWidth: annotation.lineWidth * 8)
            context.fill(path, with: .color(annotation.color.opacity(0.35 * alpha)))

        case .text:
            if let text = annotation.text, !text.isEmpty {
                context.draw(
                    Text(text)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(color),
                    at: annotation.start,
                    anchor: .topLeading
                )
            }

        case .blur:
            guard let rect = annotation.blurRect else { return }
            if let cgImg = blurredImages[annotation.id] {
                let resolved = context.resolve(Image(decorative: cgImg, scale: 1.0))
                context.draw(resolved, in: rect)
            } else {
                // ドラッグ中 / 処理待ち: プレースホルダー矩形
                context.fill(Path(rect), with: .color(Color.accentColor.opacity(0.12 * alpha)))
                context.stroke(
                    Path(rect),
                    with: .color(Color.accentColor.opacity(0.7 * alpha)),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
            }
        }
    }

    // MARK: - Private helpers

    private static func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
