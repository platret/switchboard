import Foundation

enum ServerMessage: Hashable, Sendable {
    case authOk
    case ping
    case bootstrap(Bootstrap)
    case history(agentId: String, history: History)
    case agentUpserted(Agent)
    case agentRemoved(agentId: String)
    case chatDelta(agentId: String, itemId: String, text: String)
    case chatItem(ChatItem)
    case approvalRequested(Approval)
    case approvalResolved(ApprovalResolution)
    case error(message: String)
    case unknown(type: String)
}

extension ServerMessage: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type, bootstrap, agentId, history, agent, itemId, text, item, approval, message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "auth.ok":
            self = .authOk
        case "ping":
            self = .ping
        case "bootstrap":
            self = .bootstrap(try container.decode(Bootstrap.self, forKey: .bootstrap))
        case "history":
            self = .history(agentId: try container.decode(String.self, forKey: .agentId), history: try container.decode(History.self, forKey: .history))
        case "agent.upserted":
            self = .agentUpserted(try container.decode(Agent.self, forKey: .agent))
        case "agent.removed":
            self = .agentRemoved(agentId: try container.decode(String.self, forKey: .agentId))
        case "chat.delta":
            self = .chatDelta(
                agentId: try container.decode(String.self, forKey: .agentId),
                itemId: try container.decode(String.self, forKey: .itemId),
                text: try container.decode(String.self, forKey: .text)
            )
        case "chat.item":
            self = .chatItem(try container.decode(ChatItem.self, forKey: .item))
        case "approval.requested":
            self = .approvalRequested(try container.decode(Approval.self, forKey: .approval))
        case "approval.resolved":
            self = .approvalResolved(try ApprovalResolution(from: decoder))
        case "error":
            self = .error(message: try container.decodeIfPresent(String.self, forKey: .message) ?? "Request failed")
        default:
            self = .unknown(type: type)
        }
    }
}

extension ServerMessage {
    static func parse(_ text: String) -> ServerMessage? {
        try? JSONCoding.decode(ServerMessage.self, from: text)
    }
}
