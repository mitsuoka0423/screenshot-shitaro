import AppKit

enum ImageExporter {
    /// NSViewの内容をNSImageにレンダリングして返す
    static func render(view: NSView) -> NSImage? {
        guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return nil
        }
        view.cacheDisplay(in: view.bounds, to: bitmapRep)
        let image = NSImage(size: view.bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }

    /// クリップボードにコピー
    static func copyToClipboard(view: NSView) {
        guard let image = render(view: view) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    /// NSSavePanelを使ってPNG/JPEGで保存。保存成功時は true、キャンセル・失敗時は false を返す
    @MainActor
    static func saveWithPanel(view: NSView, window: NSWindow?) async -> Bool {
        guard let image = render(view: view) else { return false }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "screenshot.png"

        let response: NSApplication.ModalResponse
        if let window {
            response = await panel.beginSheetModal(for: window)
        } else {
            response = panel.runModal()
        }

        guard response == .OK, let url = panel.url else { return false }

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return false }

        let fileType: NSBitmapImageRep.FileType = url.pathExtension.lowercased() == "jpg" ? .jpeg : .png
        guard let data = bitmapRep.representation(using: fileType, properties: [:]) else { return false }

        try? data.write(to: url)
        return true
    }
}
