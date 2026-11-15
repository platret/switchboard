import Foundation

struct MarkdownFence: Hashable {
    let marker: Character
    let length: Int
    let indent: Int
    let info: String

    var language: String? {
        info.split(separator: " ").first.map(String.init)
    }

    func closes(_ line: MarkdownLine) -> Bool {
        let run = line.content.prefix { $0 == marker }
        return run.count >= length && run.count == line.content.count
    }

    func strip(_ line: MarkdownLine) -> String {
        var remaining = indent
        var text = Substring(line.raw)
        while remaining > 0, text.first == " " {
            text = text.dropFirst()
            remaining -= 1
        }
        return String(text)
    }
}
