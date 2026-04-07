import Observation

@Observable
class AnnotationStore {
    private(set) var annotations: [Annotation] = []
    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []

    func add(_ annotation: Annotation) {
        undoStack.append(annotations)
        redoStack.removeAll()
        annotations.append(annotation)
    }

    func remove(at index: Int) {
        guard annotations.indices.contains(index) else { return }
        undoStack.append(annotations)
        redoStack.removeAll()
        annotations.remove(at: index)
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = previous
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
    }
}
