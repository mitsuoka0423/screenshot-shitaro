import AppKit
import ApplicationServices

enum PermissionChecker {
    /// アクセシビリティ権限が付与されているか確認する
    static func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 権限が未付与の場合、システム設定のアクセシビリティページを開く
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// スクリーン録画権限が付与されているか確認する
    static func hasScreenRecordingPermission() -> Bool {
        // macOS 10.15+ で CGWindowListCopyWindowInfo が空を返す場合は権限なし
        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        return windowList != nil
    }
}
