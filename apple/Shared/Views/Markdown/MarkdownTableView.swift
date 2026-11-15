import SwiftUI

struct MarkdownTableView: View {
    let header: [String]
    let rows: [[String]]

    var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 7) {
                GridRow {
                    ForEach(Array(header.enumerated()), id: \.offset) { entry in
                        cell(entry.element).fontWeight(.semibold)
                    }
                }
                Divider().gridCellUnsizedAxes(.horizontal)
                ForEach(Array(rows.enumerated()), id: \.offset) { row in
                    GridRow {
                        ForEach(Array(row.element.enumerated()), id: \.offset) { entry in
                            cell(entry.element)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Surface.sunken, in: RoundedRectangle(cornerRadius: Surface.corner, style: .continuous))
    }

    private func cell(_ text: String) -> some View {
        Text(InlineMarkdown.attributed(text))
            .font(.callout)
            .textSelection(.enabled)
            .fixedSize()
    }
}
