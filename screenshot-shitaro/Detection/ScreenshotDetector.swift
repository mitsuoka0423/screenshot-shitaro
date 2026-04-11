import Foundation
import CoreServices

/// FSEventStream を使用して ~/Desktop の .png ファイル出現を監視するクラス。
/// AppKit / CGEventTap は使用しない。
@Observable
final class ScreenshotDetector: @unchecked Sendable {
    static let shared = ScreenshotDetector()

    /// 最後に検知したスクリーンショットの URL。変化を監視して編集ウィンドウを開く。
    private(set) var latestScreenshotURL: URL?

    private var eventStream: FSEventStreamRef?

    private init() {}

    /// ~/Desktop の FSEvent 監視を開始する。
    func start() {
        guard eventStream == nil else { return }

        let desktopPath = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Desktop", directoryHint: .isDirectory)
            .path

        // C コールバックに self を渡すための context
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        // FSEventStream コールバック（@convention(c) — nonisolated）
        let callback: FSEventStreamCallback = { (_, contextInfo, numEvents, eventPaths, eventFlags, _) in
            guard let contextInfo else { return }

            let detector = Unmanaged<ScreenshotDetector>.fromOpaque(contextInfo)
                .takeUnretainedValue()

            // kFSEventStreamCreateFlagUseCFTypes により CFArray<CFString> として届く
            let pathsArray = Unmanaged<CFArray>.fromOpaque(eventPaths)
                .takeUnretainedValue() as NSArray

            for index in 0..<numEvents {
                guard let path = pathsArray[index] as? String else { continue }

                let flags = eventFlags[index]
                let isCreated = flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0
                let isFile    = flags & UInt32(kFSEventStreamEventFlagItemIsFile)    != 0
                guard isCreated, isFile, path.hasSuffix(".png") else { continue }

                // 作成時刻が直近 3 秒以内のファイルのみ対象
                let attrs = try? FileManager.default.attributesOfItem(atPath: path)
                let creationDate = attrs?[.creationDate] as? Date ?? Date()
                guard Date().timeIntervalSince(creationDate) <= 3.0 else { continue }

                let url = URL(fileURLWithPath: path)
                Task { @MainActor in
                    detector.latestScreenshotURL = url
                }
            }
        }

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [desktopPath] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // latency（秒）
            FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagUseCFTypes
            )
        ) else { return }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
        eventStream = stream
    }

    /// 監視を停止してストリームを解放する。
    func stop() {
        guard let stream = eventStream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        eventStream = nil
    }
}
