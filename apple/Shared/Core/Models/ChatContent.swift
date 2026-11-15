import Foundation

enum ChatContent: Hashable, Sendable {
    case text(String)
    case tool(ToolCall)
    case error(String)
    case notice(String)
    case unknown(kind: String)
}

extension ChatContent: Decodable {
    private enum CodingKeys: String, CodingKey {
        case kind, text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "text": self = .text(try container.decode(String.self, forKey: .text))
        case "tool": self = .tool(try ToolCall(from: decoder))
        case "error": self = .error(try container.decode(String.self, forKey: .text))
        case "notice": self = .notice(try container.decode(String.self, forKey: .text))
        default: self = .unknown(kind: kind)
        }
    }
}
