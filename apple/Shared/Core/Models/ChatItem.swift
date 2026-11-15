import Foundation

struct ChatItem: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let agentId: String
    var role: ChatRole
    var content: ChatContent
    var createdAt: Date
}
