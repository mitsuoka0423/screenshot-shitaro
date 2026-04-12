import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    private let detector = ScreenshotDetector.shared
    private let permissionChecker = PermissionChecker.shared

    var body: some View {
        Text("screenshot-shitaro")
            // スクリーンショット検知時に編集ウィンドウを開く
            .onChange(of: detector.latestScreenshotURL) { _, url in
                guard url != nil else { return }
                openWindow(id: "editor")
            }
            // 権限未取得時のアラート
            .alert("スクリーン録画の権限が必要です", isPresented: .init(
                get: { permissionChecker.needsPermissionAlert },
                set: { if !$0 { permissionChecker.dismissAlert() } }
            )) {
                Button("設定を開く") {
                    openURL(permissionChecker.settingsURL)
                    permissionChecker.dismissAlert()
                }
                Button("キャンセル", role: .cancel) {
                    permissionChecker.dismissAlert()
                }
            } message: {
                Text("スクリーンショットを自動検知するには、システム設定でスクリーン録画の権限を許可してください。")
            }
    }
}
