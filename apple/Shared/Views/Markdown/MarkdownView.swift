import SwiftUI

struct MarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(MarkdownParser.parse(text).enumerated()), id: \.offset) { entry in
                MarkdownBlockView(block: entry.element)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
