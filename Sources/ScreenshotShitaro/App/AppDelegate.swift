import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var screenshotDetector: ScreenshotDetector?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        checkPermissionsAndStartDetection()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            // SF Symbols を使用したメニューバーアイコン
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "ScreenshotShitaro"
            )
        }

        let menu = NSMenu()
        menu.addItem(
            withTitle: "エディタを開く",
            action: #selector(openEditor),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "終了",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem?.menu = menu
    }

    @objc private func openEditor() {
        EditorWindowController.open()
    }

    // MARK: - Screenshot Detection

    private func checkPermissionsAndStartDetection() {
        if PermissionChecker.hasAccessibilityPermission() {
            startDetection()
        } else {
            PermissionChecker.requestAccessibilityPermission()
            // 権限取得後でも FSEvents ベースの検知は動作するため開始する
            startDetection()
        }
    }

    private func startDetection() {
        screenshotDetector = ScreenshotDetector { [weak self] imageURL in
            Task { @MainActor in
                self?.handleScreenshotDetected(imageURL: imageURL)
            }
        }
        screenshotDetector?.start()
    }

    private func handleScreenshotDetected(imageURL: URL?) {
        EditorWindowController.open(with: imageURL)
    }
}
