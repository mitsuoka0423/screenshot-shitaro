import Foundation
import CoreGraphics

/// スクリーン録画権限を確認・要求するクラス。
/// AppKit を使用しない（アラート表示は SwiftUI 側に委譲）。
@Observable
final class PermissionChecker {
    static let shared = PermissionChecker()

    /// true の場合、権限が未取得のためアラート表示が必要。
    private(set) var needsPermissionAlert = false

    /// システム設定のスクリーン録画プライバシー画面を開く URL。
    let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    private init() {}

    /// スクリーン録画権限を確認し、未取得の場合はシステムダイアログを要求する。
    /// ダイアログ後も権限が取得されていない場合は `needsPermissionAlert` を true にする。
    func checkAndRequest() {
        guard !CGPreflightScreenCaptureAccess() else { return }

        // システムダイアログを表示して権限を要求
        CGRequestScreenCaptureAccess()

        // 要求後に再確認（初回は権限が付与されない場合が多い）
        if !CGPreflightScreenCaptureAccess() {
            needsPermissionAlert = true
        }
    }

    /// アラートを表示済みとしてフラグをリセットする。
    func dismissAlert() {
        needsPermissionAlert = false
    }
}
