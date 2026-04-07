import XCTest
@testable import ScreenshotShitaro

final class ScreenshotShitaroTests: XCTestCase {

    // MARK: - AppConstants Tests

    func testScreenshotDirectoriesExist() {
        let desktop = AppConstants.ScreenshotDirectories.desktop
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: desktop.path),
            "デスクトップディレクトリが存在すること"
        )
    }

    // MARK: - UserPreferences Tests

    func testUserPreferencesDefaults() {
        let prefs = UserPreferences.shared
        XCTAssertTrue(prefs.isHotkeyEnabled, "デフォルトでホットキーが有効であること")
        XCTAssertTrue(prefs.watchesDesktop, "デフォルトでDesktop監視が有効であること")
        XCTAssertTrue(prefs.watchesPicturesScreenshots, "デフォルトでPictures/Screenshots監視が有効であること")
    }

    func testUserPreferencesWrite() {
        let prefs = UserPreferences.shared
        prefs.isHotkeyEnabled = false
        XCTAssertFalse(prefs.isHotkeyEnabled, "ホットキー無効化が保存されること")
        // 元に戻す
        prefs.isHotkeyEnabled = true
    }

    // MARK: - PermissionChecker Tests

    func testPermissionCheckerDoesNotCrash() {
        // 権限チェック自体がクラッシュしないことを確認
        let hasPerm = PermissionChecker.hasAccessibilityPermission()
        // CI 環境では false が期待される
        XCTAssertNotNil(hasPerm)
    }
}
