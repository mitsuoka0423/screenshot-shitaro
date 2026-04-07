import AppKit

@main
struct ScreenshotShitaroApp {
    static func main() {
        let app = NSApplication.shared
        // LSUIElement = YES 相当: Dock に表示しないメニューバー常駐アプリ
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
