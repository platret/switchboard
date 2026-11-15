import Foundation

struct QueuedMessage: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let text: String
}
