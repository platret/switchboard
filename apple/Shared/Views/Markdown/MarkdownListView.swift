import SwiftUI

struct MarkdownListView: View {
    let items: [MarkdownListItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(items.enumerated()), id: \.offset) { entry in
                row(entry.element)
            }
        }
    }

    private func row(_ item: MarkdownListItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(item.number.map { "\($0)." } ?? "\u{2022}")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityHidden(item.number == nil)
            Text(InlineMarkdown.attributed(item.text))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, CGFloat(item.level) * 18)
    }
}
