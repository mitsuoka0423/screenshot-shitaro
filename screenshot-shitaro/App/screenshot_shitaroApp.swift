import SwiftUI

@main
struct ScreenshotShitaroApp: App {
    private let detector = ScreenshotDetector.shared

    init() {
        // 起動時にスクリーン録画権限を確認・要求
        PermissionChecker.shared.checkAndRequest()
        // FSEvent 監視を開始
        ScreenshotDetector.shared.start()
    }

    var body: some Scene {
        MenuBarExtra("screenshot-shitaro", systemImage: "camera.on.rectangle") {
            MenuBarView()
        }

        Window("Editor", id: "editor") {
            EditorView()
                // ScreenshotDetector をシングルトンとして環境値で注入
                .environment(detector)
        }
    }
}
