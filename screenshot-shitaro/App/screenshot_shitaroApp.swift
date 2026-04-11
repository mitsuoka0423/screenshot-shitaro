import SwiftUI

@main
struct ScreenshotShitaroApp: App {
    var body: some Scene {
        MenuBarExtra("screenshot-shitaro", systemImage: "camera.on.rectangle") {
            MenuBarView()
        }

        Window("Editor", id: "editor") {
            EditorView()
        }
    }
}
