import Foundation

struct MarkdownLine {
    let raw: String
    let indent: Int
    let content: String

    init(_ raw: String) {
        self.raw = raw
        let leading = raw.prefix { $0 == " " || $0 == "\t" }
        indent = leading.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
        content = raw.trimmingCharacters(in: .whitespaces)
    }

    var isBlank: Bool {
        content.isEmpty
    }

    var fence: MarkdownFence? {
        guard let marker = content.first, marker == "`" || marker == "~" else { return nil }
        let run = content.prefix { $0 == marker }
        guard run.count >= 3 else { return nil }
        let info = content.dropFirst(run.count).trimmingCharacters(in: .whitespaces)
        if marker == "`", info.contains("`") { return nil }
        return MarkdownFence(marker: marker, length: run.count, indent: indent, info: info)
    }

    var heading: (level: Int, text: String)? {
        let hashes = content.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count) else { return nil }
        let rest = content.dropFirst(hashes.count)
        guard rest.first == " " else { return nil }
        let text = rest.trimmingCharacters(in: .whitespaces)
        let closing = text.reversed().prefix { $0 == "#" }.count
        let cleaned = closing > 0 && closing < text.count ? String(text.dropLast(closing)).trimmingCharacters(in: .whitespaces) : text
        return (hashes.count, cleaned)
    }

    var isRule: Bool {
        let marks = content.filter { $0 != " " }
        guard marks.count >= 3, let first = marks.first, "-*_".contains(first) else { return false }
        return marks.allSatisfy { $0 == first }
    }

    var quote: String? {
        guard content.hasPrefix(">") else { return nil }
        let rest = content.dropFirst()
        return String(rest.first == " " ? rest.dropFirst() : rest)
    }

    var listItem: (number: Int?, text: String)? {
        if let marker = content.first, "-*+".contains(marker) {
            let rest = content.dropFirst()
            if rest.isEmpty { return (nil, "") }
            return rest.first == " " ? (nil, rest.trimmingCharacters(in: .whitespaces)) : nil
        }
        let digits = content.prefix { $0.isASCII && $0.isNumber }
        guard (1...9).contains(digits.count), let number = Int(digits) else { return nil }
        let rest = content.dropFirst(digits.count)
        guard let delimiter = rest.first, delimiter == "." || delimiter == ")" else { return nil }
        let text = rest.dropFirst()
        guard text.isEmpty || text.first == " " else { return nil }
        return (number, text.trimmingCharacters(in: .whitespaces))
    }

    var cells: [String] {
        var body = Substring(content)
        if body.hasPrefix("|") { body = body.dropFirst() }
        if body.hasSuffix("|"), !body.hasSuffix("\\|") { body = body.dropLast() }
        let placeholder = "\u{1F}"
        return body.replacingOccurrences(of: "\\|", with: placeholder)
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.replacingOccurrences(of: placeholder, with: "|").trimmingCharacters(in: .whitespaces) }
    }

    var isTableRow: Bool {
        !isBlank && content.contains("|")
    }

    var isTableSeparator: Bool {
        guard isTableRow, content.contains("-") else { return false }
        return cells.allSatisfy { cell in
            !cell.isEmpty && cell.contains("-") && cell.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }
}
