import Foundation

struct HostLog: Hashable, Sendable {
    static let limit = 200

    private(set) var lines: [String] = []
    private var partial = ""

    mutating func append(_ chunk: String) {
        let pieces = (partial + HostLog.plain(chunk)).split(separator: "\n", omittingEmptySubsequences: false)
        partial = pieces.last.map(String.init) ?? ""
        lines.append(contentsOf: pieces.dropLast().map { String($0).trimmingCharacters(in: .newlines) })
        if lines.count > HostLog.limit { lines.removeFirst(lines.count - HostLog.limit) }
    }

    mutating func note(_ line: String) {
        append(line + "\n")
    }

    static func plain(_ text: String) -> String {
        var output = ""
        var skipping = false
        for character in text.replacingOccurrences(of: "\r\n", with: "\n") {
            if skipping {
                if character.isLetter { skipping = false }
            } else if character == "\u{1B}" {
                skipping = true
            } else if character != "\r" {
                output.append(character)
            }
        }
        return output
    }
}
