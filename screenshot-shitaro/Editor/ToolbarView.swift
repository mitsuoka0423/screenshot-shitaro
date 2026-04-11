import SwiftUI

struct ToolbarView: View {
    @Bindable var store: AnnotationStore
    var onUndo: () -> Void
    var onRedo: () -> Void

    private let tools: [(AnnotationTool, String, String)] = [
        (.arrow,     "矢印",     "arrow.up.right"),
        (.rect,      "矩形",     "rectangle"),
        (.circle,    "円",       "circle"),
        (.line,      "直線",     "line.diagonal"),
        (.text,      "テキスト", "textformat"),
        (.blur,      "ぼかし",   "drop.degreesign"),
        (.highlight, "ハイライト","highlighter"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            // ツール選択
            ForEach(tools, id: \.0) { tool, label, icon in
                Button {
                    store.currentTool = tool
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                        Text(label)
                            .font(.system(size: 9))
                    }
                    .frame(width: 48, height: 40)
                }
                .buttonStyle(.bordered)
                .tint(store.currentTool == tool ? .accentColor : nil)
                .help(label)
            }

            Divider().frame(height: 36)

            // カラーピッカー
            ColorPicker("", selection: $store.strokeColor, supportsOpacity: false)
                .frame(width: 36)
                .help("色")

            // 線幅スライダー
            HStack(spacing: 4) {
                Image(systemName: "line.diagonal")
                    .font(.system(size: 10))
                Slider(value: $store.lineWidth, in: 1...20, step: 1)
                    .frame(width: 80)
                Text("\(Int(store.lineWidth))pt")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .frame(width: 28, alignment: .trailing)
            }

            Divider().frame(height: 36)

            // Undo / Redo
            Button {
                onUndo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .help("元に戻す (⌘Z)")
            .keyboardShortcut("z", modifiers: .command)

            Button {
                onRedo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .help("やり直す (⌘⇧Z)")
            .keyboardShortcut("z", modifiers: [.command, .shift])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
