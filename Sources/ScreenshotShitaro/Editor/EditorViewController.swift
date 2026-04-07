import AppKit

class EditorViewController: NSViewController {
    let store = AnnotationStore()
    private let image: NSImage

    private var canvasView: CanvasView!
    private var toolbarView: ToolbarView!

    init(image: NSImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        canvasView = CanvasView(image: image, store: store)
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        toolbarView = ToolbarView()
        toolbarView.delegate = self
        toolbarView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toolbarView)
        view.addSubview(canvasView)

        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 44),

            canvasView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - ToolbarViewDelegate

extension EditorViewController: ToolbarViewDelegate {
    func toolbar(_ toolbar: ToolbarView, didSelectTool tool: AnnotationTool) {
        // CanvasView に選択中ツールを伝える（#5 実装後に接続）
    }

    func toolbar(_ toolbar: ToolbarView, didChangeColor color: NSColor) {
        // CanvasView に色変更を伝える（#5 実装後に接続）
    }

    func toolbar(_ toolbar: ToolbarView, didChangeLineWidth width: CGFloat) {
        // CanvasView に線幅変更を伝える（#5 実装後に接続）
    }

    func toolbar(_ toolbar: ToolbarView, didChangeFontSize size: CGFloat) {
        // CanvasView にフォントサイズ変更を伝える（#5 実装後に接続）
    }

    func toolbarDidRequestUndo(_ toolbar: ToolbarView) {
        store.undo()
    }

    func toolbarDidRequestRedo(_ toolbar: ToolbarView) {
        store.redo()
    }
}
