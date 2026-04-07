import AppKit

/// テキスト注釈の入力用 NSTextField オーバーレイ
@MainActor
final class TextInputOverlay: NSView {

    private let textField: NSTextField
    private let onCommit: (String) -> Void
    private let style: AnnotationStyle

    init(origin: CGPoint, style: AnnotationStyle, onCommit: @escaping (String) -> Void) {
        self.style = style
        self.onCommit = onCommit

        let initialSize = CGSize(width: 200, height: 30)
        textField = NSTextField(frame: CGRect(origin: .zero, size: initialSize))

        super.init(frame: CGRect(origin: origin, size: initialSize))

        setupTextField()
        addSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未サポート")
    }

    private func setupTextField() {
        textField.isEditable = true
        textField.isBordered = true
        textField.backgroundColor = NSColor.white.withAlphaComponent(0.9)
        textField.textColor = style.color
        textField.font = NSFont.systemFont(ofSize: style.fontSize)
        textField.placeholderString = "テキストを入力..."
        textField.autoresizingMask = [.width]
        textField.target = self
        textField.action = #selector(commitText)
        textField.focusRingType = .exterior
    }

    /// フォーカスを設定してテキスト入力を開始する
    func activate() {
        window?.makeFirstResponder(textField)
    }

    @objc private func commitText() {
        let text = textField.stringValue
        onCommit(text)
        removeFromSuperview()
    }

    /// フォーカスが外れた場合もコミット
    override func resignFirstResponder() -> Bool {
        commitText()
        return super.resignFirstResponder()
    }
}
