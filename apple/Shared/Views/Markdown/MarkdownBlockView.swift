import SwiftUI

struct MarkdownBlockView: View {
    let block: MarkdownBlock

    var body: some View {
        switch block {
        case .heading(let level, let text):
            inline(text)
                .font(MarkdownBlockView.headingFont(level))
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            inline(text)
        case .bulletList(let items), .numberedList(let items):
            MarkdownListView(items: items)
        case .code(let language, let text):
            CodeBlockView(language: language, text: text)
        case .quote(let text):
            inline(text)
                .foregroundStyle(.secondary)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5).fill(Surface.hairline).frame(width: 3)
                }
        case .table(let header, let rows):
            MarkdownTableView(header: header, rows: rows)
        case .rule:
            Divider()
        }
    }

    private func inline(_ text: String) -> some View {
        Text(InlineMarkdown.attributed(text))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    private static func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .title2.bold()
        case 2: .title3.weight(.semibold)
        default: .headline
        }
    }
}
