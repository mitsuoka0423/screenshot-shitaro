import AppKit

@MainActor
final class EditorWindowController: NSWindowController {
    private static var currentController: EditorWindowController?

    private let editorVC: EditorViewController

    init(image: NSImage) {
        editorVC = EditorViewController(image: image)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScreenshotShitaro"
        window.isReleasedWhenClosed = false
        window.contentViewController = editorVC
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未サポートです")
    }

    // MARK: - Factory

    /// エディタウィンドウを開く（スクリーンショット検知時・メニューから呼ばれる）
    static func open(with imageURL: URL? = nil) {
        let image: NSImage
        if let url = imageURL, let loaded = NSImage(contentsOf: url) {
            image = loaded
        } else {
            image = NSImage(size: NSSize(width: 800, height: 600))
        }
        let controller = EditorWindowController(image: image)
        currentController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Key Commands

    override func keyDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.command) else {
            super.keyDown(with: event)
            return
        }
        switch event.charactersIgnoringModifiers {
        case "c":
            handleCopy()
        case "s":
            handleSave()
        default:
            super.keyDown(with: event)
        }
    }

    private func handleCopy() {
        guard let canvasView = editorVC.view.subviews.first(where: { $0 is CanvasView }) else { return }
        ImageExporter.copyToClipboard(view: canvasView)
        close()
    }

    private func handleSave() {
        guard let canvasView = editorVC.view.subviews.first(where: { $0 is CanvasView }) else { return }
        Task { @MainActor in
            let saved = await ImageExporter.saveWithPanel(view: canvasView, window: self.window)
            if saved { self.close() }
        }
    }
}

// MARK: - NSWindowDelegate

extension EditorWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if EditorWindowController.currentController === self {
            EditorWindowController.currentController = nil
        }
    }
}
