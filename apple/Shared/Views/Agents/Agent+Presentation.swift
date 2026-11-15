import Foundation

extension Agent {
    var previewLine: String? {
        guard let preview, !preview.isEmpty else { return nil }
        let plain = InlineMarkdown.plain(preview).split(whereSeparator: \.isNewline).joined(separator: " ")
        return plain.isEmpty ? nil : plain
    }

    var statusLine: String {
        switch status {
        case .working: activity ?? "Working"
        case .waiting: "Waiting for your approval"
        case .error: previewLine ?? "Stopped with an error"
        case .idle: previewLine ?? "No messages yet"
        }
    }

    var hasActivityDate: Bool {
        lastActivityAt > .distantPast
    }
}
