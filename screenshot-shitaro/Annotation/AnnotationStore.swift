import SwiftUI
import Observation

@Observable final class AnnotationStore {
    var annotations: [Annotation] = []
    var currentTool: AnnotationTool = .arrow
    var strokeColor: Color = .red
    var lineWidth: CGFloat = 3

    func add(_ annotation: Annotation, undoManager: UndoManager?) {
        annotations.append(annotation)
        undoManager?.registerUndo(withTarget: self) { store in
            store.annotations.removeAll { $0.id == annotation.id }
        }
    }

    func removeAll() {
        annotations.removeAll()
    }
}
