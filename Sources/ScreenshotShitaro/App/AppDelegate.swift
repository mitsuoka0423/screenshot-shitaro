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
        // アクセシビリティ権限チェック
        if !PermissionChecker.hasAccessibilityPermission() {
            PermissionChecker.requestAccessibilityPermission()
        }

        // スクリーン録画権限チェック
        // 未付与の場合はシステム設定（プライバシーとセキュリティ → 画面収録）へ誘導
        if !PermissionChecker.hasScreenRecordingPermission() {
            PermissionChecker.requestScreenRecordingPermission()
        }

        // 権限の有無によらず FSEvents ベースの検知は開始する
        startDetection()
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
