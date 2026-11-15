import Foundation

struct MarkdownParser {
    private let lines: [MarkdownLine]
    private var index = 0
    private var blocks: [MarkdownBlock] = []
    private var paragraph: [String] = []

    static func parse(_ text: String) -> [MarkdownBlock] {
        var parser = MarkdownParser(text)
        return parser.run()
    }

    private init(_ text: String) {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map { MarkdownLine(String($0)) }
    }

    private mutating func run() -> [MarkdownBlock] {
        while index < lines.count {
            let line = lines[index]
            if let fence = line.fence {
                readCode(fence)
            } else if line.isBlank {
                flush()
                index += 1
            } else if let heading = line.heading {
                emit(.heading(level: heading.level, text: heading.text))
            } else if line.isRule {
                emit(.rule)
            } else if line.quote != nil {
                readQuote()
            } else if line.listItem != nil {
                readList()
            } else if startsTable {
                readTable()
            } else {
                paragraph.append(line.content)
                index += 1
            }
        }
        flush()
        return blocks
    }

    private var startsTable: Bool {
        index + 1 < lines.count && lines[index].isTableRow && lines[index + 1].isTableSeparator
    }

    private mutating func flush() {
        guard !paragraph.isEmpty else { return }
        blocks.append(.paragraph(paragraph.joined(separator: "\n")))
        paragraph = []
    }

    private mutating func emit(_ block: MarkdownBlock) {
        flush()
        blocks.append(block)
        index += 1
    }

    private mutating func readCode(_ fence: MarkdownFence) {
        flush()
        index += 1
        var body: [String] = []
        while index < lines.count, !fence.closes(lines[index]) {
            body.append(fence.strip(lines[index]))
            index += 1
        }
        index += 1
        blocks.append(.code(language: fence.language, text: body.joined(separator: "\n")))
    }

    private mutating func readQuote() {
        flush()
        var body: [String] = []
        while index < lines.count, let text = lines[index].quote {
            body.append(text)
            index += 1
        }
        blocks.append(.quote(body.joined(separator: "\n")))
    }

    private mutating func readTable() {
        flush()
        let header = lines[index].cells
        index += 2
        var rows: [[String]] = []
        while index < lines.count, lines[index].isTableRow {
            let cells = lines[index].cells
            rows.append((0..<header.count).map { $0 < cells.count ? cells[$0] : "" })
            index += 1
        }
        blocks.append(.table(header: header, rows: rows))
    }

    private mutating func readList() {
        flush()
        var entries: [(indent: Int, number: Int?, text: String)] = []
        while index < lines.count {
            let line = lines[index]
            if line.fence != nil { break }
            if line.isBlank {
                guard index + 1 < lines.count, continuesList(lines[index + 1], after: entries) else { break }
            } else if continuesList(line, after: entries), let item = line.listItem {
                entries.append((line.indent, item.number, item.text))
            } else if line.indent > 0, line.listItem == nil, !entries.isEmpty {
                entries[entries.count - 1].text += "\n" + line.content
            } else {
                break
            }
            index += 1
        }
        let indents = Set(entries.map(\.indent)).sorted()
        let items = entries.map { MarkdownListItem(level: indents.firstIndex(of: $0.indent) ?? 0, number: $0.number, text: $0.text) }
        blocks.append(entries.first?.number == nil ? .bulletList(items) : .numberedList(items))
    }

    private func continuesList(_ line: MarkdownLine, after entries: [(indent: Int, number: Int?, text: String)]) -> Bool {
        guard let item = line.listItem, !line.isRule else { return false }
        guard let first = entries.first else { return true }
        return line.indent > first.indent || (item.number == nil) == (first.number == nil)
    }
}
