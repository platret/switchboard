import Foundation

@MainActor
enum ComposerDrafts {
    private static var texts: [String: String] = [:]

    static func text(for agentId: String) -> String {
        texts[agentId] ?? ""
    }

    static func save(_ text: String, for agentId: String) {
        texts[agentId] = text.isEmpty ? nil : text
    }
}
