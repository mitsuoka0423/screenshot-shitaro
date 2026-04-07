import Testing
import CoreGraphics
@testable import ScreenshotShitaro

@Suite("AnnotationStore")
struct AnnotationStoreTests {

    @Test("add: アノテーションが追加される")
    func addAnnotation() {
        let store = AnnotationStore()
        let style = AnnotationStyle()
        store.add(.arrow(start: .zero, end: CGPoint(x: 10, y: 10), style: style))
        #expect(store.annotations.count == 1)
    }

    @Test("add: 複数追加できる")
    func addMultiple() {
        let store = AnnotationStore()
        let style = AnnotationStyle()
        store.add(.rect(frame: CGRect(x: 0, y: 0, width: 100, height: 50), style: style))
        store.add(.blur(frame: CGRect(x: 10, y: 10, width: 30, height: 30)))
        #expect(store.annotations.count == 2)
    }

    @Test("undo: 直前のaddを取り消す")
    func undoAdd() {
        let store = AnnotationStore()
        let style = AnnotationStyle()
        store.add(.circle(frame: CGRect(x: 0, y: 0, width: 50, height: 50), style: style))
        store.undo()
        #expect(store.annotations.isEmpty)
    }

    @Test("undo: 空のときは何もしない")
    func undoEmpty() {
        let store = AnnotationStore()
        store.undo()
        #expect(store.annotations.isEmpty)
    }

    @Test("redo: undoを元に戻す")
    func redoAfterUndo() {
        let store = AnnotationStore()
        let style = AnnotationStyle()
        store.add(.line(start: .zero, end: CGPoint(x: 5, y: 5), style: style))
        store.undo()
        store.redo()
        #expect(store.annotations.count == 1)
    }

    @Test("redo: addの後はredoスタックがリセットされる")
    func redoStackClearedOnAdd() {
        let store = AnnotationStore()
        let style = AnnotationStyle()
        store.add(.text(origin: .zero, content: "hello", style: style))
        store.undo()
        store.add(.highlight(frame: CGRect(x: 0, y: 0, width: 20, height: 10), style: style))
        store.redo() // redoスタックは空なので何も起きない
        #expect(store.annotations.count == 1)
    }

    @Test("undo/redo: 複数回の操作")
    func multipleUndoRedo() {
        let store = AnnotationStore()
        let style = AnnotationStyle()
        store.add(.arrow(start: .zero, end: CGPoint(x: 1, y: 1), style: style))
        store.add(.rect(frame: .zero, style: style))
        store.undo()
        #expect(store.annotations.count == 1)
        store.undo()
        #expect(store.annotations.isEmpty)
        store.redo()
        #expect(store.annotations.count == 1)
        store.redo()
        #expect(store.annotations.count == 2)
    }

    @Test("remove: 指定インデックスを削除できる")
    func removeAnnotation() {
        let store = AnnotationStore()
        let style = AnnotationStyle()
        store.add(.blur(frame: .zero))
        store.add(.circle(frame: .zero, style: style))
        store.remove(at: 0)
        #expect(store.annotations.count == 1)
    }

    @Test("remove: 範囲外インデックスは無視される")
    func removeOutOfBounds() {
        let store = AnnotationStore()
        store.remove(at: 99)
        #expect(store.annotations.isEmpty)
    }
}
