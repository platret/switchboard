import Foundation

struct ChatDraft: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    var text: String
}
