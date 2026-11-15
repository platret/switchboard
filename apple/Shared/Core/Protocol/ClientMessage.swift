import Foundation

enum ClientMessage: Hashable, Sendable {
    static let chatTextMaxLength = 100_000

    case auth(token: String)
    case chatSend(agentId: String, text: String)
    case historyGet(agentId: String)
    case agentStop(agentId: String)
    case queueRemove(agentId: String, id: String)
    case approvalRespond(approvalId: String, decision: ApprovalDecision, scope: ApprovalScope)
}

extension ClientMessage: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type, token, agentId, text, id, approvalId, decision, scope
    }

    var type: String {
        switch self {
        case .auth: "auth"
        case .chatSend: "chat.send"
        case .historyGet: "history.get"
        case .agentStop: "agent.stop"
        case .queueRemove: "queue.remove"
        case .approvalRespond: "approval.respond"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        switch self {
        case .auth(let token):
            try container.encode(token, forKey: .token)
        case .chatSend(let agentId, let text):
            try container.encode(agentId, forKey: .agentId)
            try container.encode(text, forKey: .text)
        case .historyGet(let agentId), .agentStop(let agentId):
            try container.encode(agentId, forKey: .agentId)
        case .queueRemove(let agentId, let id):
            try container.encode(agentId, forKey: .agentId)
            try container.encode(id, forKey: .id)
        case .approvalRespond(let approvalId, let decision, let scope):
            try container.encode(approvalId, forKey: .approvalId)
            try container.encode(decision, forKey: .decision)
            try container.encode(scope, forKey: .scope)
        }
    }
}
