import AppKit

/// 注釈エディタウィンドウのコントローラ（スタブ実装）
/// フェーズ2（Issue #5, #6）で本実装に置き換える
@MainActor
final class EditorWindowController: NSWindowController {
    private static var currentController: EditorWindowController?

    private let imageURL: URL?

    init(imageURL: URL?) {
        self.imageURL = imageURL
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScreenshotShitaro"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        setupPlaceholderContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未サポートです")
    }

    // MARK: - Factory

    /// エディタウィンドウを開く（既存ウィンドウがあれば前面に出す）
    static func open(with imageURL: URL? = nil) {
        if currentController == nil {
            currentController = EditorWindowController(imageURL: imageURL)
        }
        currentController?.showWindow(nil)
        currentController?.window?.center()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Placeholder UI

    private func setupPlaceholderContent() {
        let label = NSTextField(labelWithString: "Editor Stub\n（フェーズ2で実装）")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false

        let urlLabel = NSTextField(
            labelWithString: imageURL.map { "File: \($0.lastPathComponent)" } ?? "No file"
        )
        urlLabel.alignment = .center
        urlLabel.textColor = .secondaryLabelColor
        urlLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [label, urlLabel])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        window?.contentView = contentView
    }
}
