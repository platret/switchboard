import SwiftUI

struct CodeBlockView: View {
    let language: String?
    let text: String

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Surface.corner, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language ?? "Code").font(.caption).foregroundStyle(.secondary)
                Spacer()
                CopyButton(text: text, label: "Copy code")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            Divider()
            ScrollView(.horizontal) {
                Text(text)
                    .font(Surface.code)
                    .textSelection(.enabled)
                    .fixedSize()
                    .padding(12)
            }
        }
        .background(Surface.sunken, in: shape)
        .overlay(shape.strokeBorder(Surface.hairline))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.map { "Code block, \($0)" } ?? "Code block")
    }
}
