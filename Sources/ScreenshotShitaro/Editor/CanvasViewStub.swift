import AppKit

// CanvasView は Issue #5 で実装される。
// EditorViewController がコンパイルできるようスタブを提供する。
class CanvasView: NSView {
    init(image: NSImage, store: AnnotationStore) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
