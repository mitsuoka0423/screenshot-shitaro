import Foundation

enum AppConstants {
    static let appName = "ScreenshotShitaro"
    static let bundleIdentifier = "com.mitsuoka0423.ScreenshotShitaro"

    enum ScreenshotDirectories {
        static let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
        static let picturesScreenshots = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures/Screenshots")
    }

    enum Hotkey {
        /// ⌘+Shift+A: カスタムホットキーで編集ウィンドウを開く
        static let keyCode: UInt16 = 0x00  // 'A' key
        static let modifiers: UInt64 = 1 << 55 | 1 << 56  // Shift + Command
    }
}
