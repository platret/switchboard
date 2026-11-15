import SwiftUI

struct CodeSnippet: View {
    let text: String
    var label: String?
    var tone: CodeTone = .plain
    var collapsedLines = 10

    @State private var isExpanded = false

    private static let chunkSize = 12_000

    private var pieces: [String] {
        isExpanded ? TextChunks.split(text, limit: CodeSnippet.chunkSize) : [String(text.prefix(CodeSnippet.chunkSize))]
    }

    private var lineCount: Int {
        text.reduce(into: 1) { count, character in
            if character.isNewline { count += 1 }
        }
    }

    private var isLong: Bool {
        lineCount > collapsedLines || text.count > collapsedLines * 90
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label { title(label) }
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                    Text(piece)
                        .font(Surface.code)
                        .lineLimit(isExpanded ? nil : collapsedLines)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .background(tone.fill, in: shape)
            .overlay(shape.strokeBorder(tone.stroke))
            if isLong {
                HStack(spacing: 12) {
                    Button(isExpanded ? "Show less" : "Show all \(lineCount) lines") { isExpanded.toggle() }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    CopyButton(text: text, label: "Copy all")
                }
            }
        }
    }

    @ViewBuilder private func title(_ label: String) -> some View {
        if let symbol = tone.symbol {
            Label(label, systemImage: symbol).font(.caption).foregroundStyle(tone.tint ?? .secondary)
        } else {
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
