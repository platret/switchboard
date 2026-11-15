import Foundation

struct MarkdownListItem: Hashable, Sendable {
    var level: Int
    var number: Int?
    var text: String
}
