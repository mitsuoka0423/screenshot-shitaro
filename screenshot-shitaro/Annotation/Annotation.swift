import SwiftUI

enum AnnotationTool: Sendable, Equatable {
    case arrow, rect, circle, line, text, blur, highlight
}

struct Annotation: Identifiable, Sendable, Equatable {
    let id: UUID
    var tool: AnnotationTool
    var start: CGPoint
    var end: CGPoint
    var color: Color
    var lineWidth: CGFloat
    var text: String?
    var blurRect: CGRect?
}
