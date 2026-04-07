import Foundation

/// FSEvents を使ってディレクトリのファイル生成を監視するラッパー
/// ~/Desktop と ~/Pictures/Screenshots を対象とする
final class FileSystemWatcher: @unchecked Sendable {
    private let paths: [String]
    private var streamRef: FSEventStreamRef?

    /// ファイルが作成または変更されたときに呼ばれるコールバック
    var onFileEvent: ((URL) -> Void)?

    init(paths: [String]) {
        self.paths = paths
    }

    // MARK: - Start / Stop

    func start() {
        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        var context = FSEventStreamContext(
            version: 0,
            info: selfPtr,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fsEventsCallback,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,  // latency in seconds
            flags
        ) else { return }

        self.streamRef = stream
        let queue = DispatchQueue.main
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
    }

    // MARK: - Event Handling (called from C callback)

    fileprivate func handleEvents(paths: [String], flags: [FSEventStreamEventFlags]) {
        for (path, flag) in zip(paths, flags) {
            let isCreated = (flag & UInt32(kFSEventStreamEventFlagItemCreated)) != 0
            let isFile = (flag & UInt32(kFSEventStreamEventFlagItemIsFile)) != 0

            guard isCreated && isFile else { continue }

            let url = URL(fileURLWithPath: path)
            guard isScreenshotFile(url: url) else { continue }

            Task { @MainActor in
                self.onFileEvent?(url)
            }
        }
    }

    private func isScreenshotFile(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "png" || ext == "jpg" || ext == "jpeg"
    }
}

// MARK: - C Callback

private let fsEventsCallback: FSEventStreamCallback = { _, clientCallBackInfo, numEvents, eventPaths, eventFlags, _ in
    guard let clientCallBackInfo else { return }
    let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(clientCallBackInfo).takeUnretainedValue()

    // kFSEventStreamCreateFlagUseCFTypes を使用しているため CFArray として取得
    let cfPaths = unsafeBitCast(eventPaths, to: CFArray.self)
    guard let pathsArray = cfPaths as? [String] else { return }

    var flagsArray: [FSEventStreamEventFlags] = []
    let flagsPtr = UnsafeBufferPointer(start: eventFlags, count: numEvents)
    flagsArray = Array(flagsPtr)

    watcher.handleEvents(paths: pathsArray, flags: flagsArray)
}
