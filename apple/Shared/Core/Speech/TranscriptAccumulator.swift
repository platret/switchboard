import Foundation

struct TranscriptAccumulator: Hashable, Sendable {
    private(set) var committed = ""
    private(set) var current = ""

    var text: String {
        TranscriptAccumulator.join(committed, current)
    }

    mutating func update(_ partial: String) {
        let restarted = current.count >= 12 && partial.count * 2 < current.count
        if restarted { committed = text }
        current = partial
    }

    static func join(_ first: String, _ second: String) -> String {
        let head = first.trimmingCharacters(in: .whitespacesAndNewlines)
        let tail = second.trimmingCharacters(in: .whitespacesAndNewlines)
        if head.isEmpty || tail.isEmpty { return head + tail }
        return first.hasSuffix("\n") ? first + tail : head + " " + tail
    }
}
