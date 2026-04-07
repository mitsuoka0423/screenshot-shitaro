import AppKit

struct AnnotationStyle {
    var color: NSColor
    var lineWidth: CGFloat
    var fontSize: CGFloat

    init(color: NSColor = .red, lineWidth: CGFloat = 2.0, fontSize: CGFloat = 16.0) {
        self.color = color
        self.lineWidth = lineWidth
        self.fontSize = fontSize
    }
}
