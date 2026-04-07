import AppKit

enum AnnotationTool: String, CaseIterable {
    case arrow, rect, circle, line, text, blur, highlight
}

@MainActor
protocol ToolbarViewDelegate: AnyObject {
    func toolbar(_ toolbar: ToolbarView, didSelectTool tool: AnnotationTool)
    func toolbar(_ toolbar: ToolbarView, didChangeColor color: NSColor)
    func toolbar(_ toolbar: ToolbarView, didChangeLineWidth width: CGFloat)
    func toolbar(_ toolbar: ToolbarView, didChangeFontSize size: CGFloat)
    func toolbarDidRequestUndo(_ toolbar: ToolbarView)
    func toolbarDidRequestRedo(_ toolbar: ToolbarView)
}

class ToolbarView: NSView {
    weak var delegate: ToolbarViewDelegate?

    private(set) var selectedTool: AnnotationTool = .arrow
    private(set) var selectedColor: NSColor = .red
    private(set) var lineWidth: CGFloat = 2.0
    private(set) var fontSize: CGFloat = 16.0

    // MARK: - UI Components

    private let toolSegmented: NSSegmentedControl = {
        let labels = AnnotationTool.allCases.map(\.rawValue)
        let control = NSSegmentedControl(labels: labels, trackingMode: .selectOne, target: nil, action: nil)
        control.selectedSegment = 0
        return control
    }()

    private let colorWell: NSColorWell = {
        let well = NSColorWell()
        well.color = .red
        return well
    }()

    private let lineWidthSlider: NSSlider = {
        let slider = NSSlider(value: 2.0, minValue: 1.0, maxValue: 20.0, target: nil, action: nil)
        slider.controlSize = .small
        return slider
    }()

    private let fontSizeSlider: NSSlider = {
        let slider = NSSlider(value: 16.0, minValue: 8.0, maxValue: 72.0, target: nil, action: nil)
        slider.controlSize = .small
        return slider
    }()

    private lazy var undoButton = NSButton(title: "Undo", target: self, action: #selector(undoTapped))
    private lazy var redoButton = NSButton(title: "Redo", target: self, action: #selector(redoTapped))

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        toolSegmented.target = self
        toolSegmented.action = #selector(toolChanged)

        colorWell.target = self
        colorWell.action = #selector(colorChanged)

        lineWidthSlider.target = self
        lineWidthSlider.action = #selector(lineWidthChanged)

        fontSizeSlider.target = self
        fontSizeSlider.action = #selector(fontSizeChanged)

        let lineWidthLabel = NSTextField(labelWithString: "線幅")
        let fontSizeLabel = NSTextField(labelWithString: "文字")

        let stack = NSStackView(views: [
            toolSegmented,
            colorWell,
            lineWidthLabel, lineWidthSlider,
            fontSizeLabel, fontSizeSlider,
            undoButton, redoButton
        ])
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func toolChanged() {
        let index = toolSegmented.selectedSegment
        let tools = AnnotationTool.allCases
        guard tools.indices.contains(index) else { return }
        selectedTool = tools[index]
        delegate?.toolbar(self, didSelectTool: selectedTool)
    }

    @objc private func colorChanged() {
        selectedColor = colorWell.color
        delegate?.toolbar(self, didChangeColor: selectedColor)
    }

    @objc private func lineWidthChanged() {
        lineWidth = CGFloat(lineWidthSlider.doubleValue)
        delegate?.toolbar(self, didChangeLineWidth: lineWidth)
    }

    @objc private func fontSizeChanged() {
        fontSize = CGFloat(fontSizeSlider.doubleValue)
        delegate?.toolbar(self, didChangeFontSize: fontSize)
    }

    @objc private func undoTapped() {
        delegate?.toolbarDidRequestUndo(self)
    }

    @objc private func redoTapped() {
        delegate?.toolbarDidRequestRedo(self)
    }
}
