import CoreGraphics

enum Annotation {
    case arrow(start: CGPoint, end: CGPoint, style: AnnotationStyle)
    case rect(frame: CGRect, style: AnnotationStyle)
    case circle(frame: CGRect, style: AnnotationStyle)
    case line(start: CGPoint, end: CGPoint, style: AnnotationStyle)
    case text(origin: CGPoint, content: String, style: AnnotationStyle)
    case blur(frame: CGRect)
    case highlight(frame: CGRect, style: AnnotationStyle)
}
