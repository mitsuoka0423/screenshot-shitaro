import Foundation

/// スクリーンショット検知の統合クラス
/// CGEventTap（一次）+ FSEvents（フォールバック）の二段構えで検知する
@MainActor
final class ScreenshotDetector {
    private var eventTapMonitor: EventTapMonitor?
    private var fileSystemWatcher: FileSystemWatcher?

    /// スクリーンショット検知時に呼ばれるコールバック（撮影されたファイルURLを渡す）
    private let onDetected: (URL?) -> Void

    /// CGEventTap でスクショキー検知後、FSEvents でファイル確定を待つための一時フラグ
    private var pendingScreenshotKey = false

    init(onDetected: @escaping (URL?) -> Void) {
        self.onDetected = onDetected
    }

    // MARK: - Start / Stop

    func start() {
        startEventTap()
        startFileSystemWatcher()
    }

    func stop() {
        eventTapMonitor?.stop()
        fileSystemWatcher?.stop()
    }

    // MARK: - EventTap

    private func startEventTap() {
        let monitor = EventTapMonitor()
        monitor.onScreenshotKeyDetected = { [weak self] in
            Task { @MainActor in
                self?.handleScreenshotKeyDetected()
            }
        }
        monitor.onHotkeyDetected = { [weak self] in
            Task { @MainActor in
                self?.onDetected(nil)
            }
        }
        let started = monitor.start()
        if started {
            self.eventTapMonitor = monitor
        }
        // 権限なしの場合は EventTap なし。FSEvents のみで動作継続。
    }

    private func handleScreenshotKeyDetected() {
        // スクショキー検知フラグをセット
        // FSEvents でファイルが来たら onDetected を呼ぶ
        pendingScreenshotKey = true
        // 3 秒以内にファイルが来なければフラグをリセット
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run { self.pendingScreenshotKey = false }
        }
    }

    // MARK: - FileSystemWatcher

    private func startFileSystemWatcher() {
        var watchPaths: [String] = []
        let prefs = UserPreferences.shared

        if prefs.watchesDesktop {
            watchPaths.append(AppConstants.ScreenshotDirectories.desktop.path)
        }
        if prefs.watchesPicturesScreenshots {
            watchPaths.append(AppConstants.ScreenshotDirectories.picturesScreenshots.path)
        }

        guard !watchPaths.isEmpty else { return }

        let watcher = FileSystemWatcher(paths: watchPaths)
        watcher.onFileEvent = { [weak self] url in
            Task { @MainActor in
                self?.handleNewFile(url: url)
            }
        }
        watcher.start()
        self.fileSystemWatcher = watcher
    }

    private func handleNewFile(url: URL) {
        if pendingScreenshotKey {
            // EventTap と FSEvents の両方で検知: 確実にスクリーンショット
            pendingScreenshotKey = false
            onDetected(url)
        } else {
            // FSEvents のみ: ファイル名でスクリーンショットか判定
            if isLikelyScreenshot(url: url) {
                onDetected(url)
            }
        }
    }

    /// macOS のスクリーンショットファイル名パターンで判定
    private func isLikelyScreenshot(url: URL) -> Bool {
        let name = url.deletingPathExtension().lastPathComponent
        // macOS 標準: "スクリーンショット 2026-04-07 10.30.00" / "Screenshot 2026-04-07 at 10.30.00"
        return name.hasPrefix("スクリーンショット") || name.hasPrefix("Screenshot")
    }
}
