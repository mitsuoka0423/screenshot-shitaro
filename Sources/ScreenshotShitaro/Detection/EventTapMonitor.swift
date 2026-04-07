import Cocoa

/// CGEventTap を使ってキーボードイベントを監視するラッパー
/// スクリーンショットキー（⌘+Shift+3/4/5）とカスタムホットキーを検知する
final class EventTapMonitor: @unchecked Sendable {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onScreenshotKeyDetected: (() -> Void)?
    var onHotkeyDetected: (() -> Void)?

    // MARK: - Start / Stop

    func start() -> Bool {
        guard AXIsProcessTrusted() else { return false }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: selfPtr
        ) else {
            Unmanaged.passUnretained(self).release()
            return false
        }

        self.eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Event Handling (called from C callback)

    fileprivate func handleEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        guard type == .keyDown else { return event }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let isCommand = flags.contains(.maskCommand)
        let isShift = flags.contains(.maskShift)

        // ⌘+Shift+3, ⌘+Shift+4, ⌘+Shift+5 の検知
        if isCommand && isShift {
            switch keyCode {
            case 20, 21, 23:  // 3=20, 4=21, 5=23 (US keyboard)
                Task { @MainActor in
                    self.onScreenshotKeyDetected?()
                }
            case 0:  // 'A' key: カスタムホットキー ⌘+Shift+A
                Task { @MainActor in
                    self.onHotkeyDetected?()
                }
            default:
                break
            }
        }

        return event
    }
}

// MARK: - C Callback

private let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<EventTapMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    if let result = monitor.handleEvent(type: type, event: event) {
        return Unmanaged.passUnretained(result)
    }
    return nil
}
