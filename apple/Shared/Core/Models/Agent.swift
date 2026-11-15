import Foundation

struct Agent: Hashable, Identifiable, Sendable {
    let id: String
    var name: String
    var projectId: String
    var role: String
    var sessionId: String?
    var status: AgentStatus = .idle
    var createdAt: Date = .distantPast
    var lastActivityAt: Date = .distantPast
    var preview: String?
    var activity: String?
    var queue: [QueuedMessage] = []
    var trustedTools: [String] = []
}

extension Agent: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, name, projectId, role, sessionId, status, createdAt, lastActivityAt, preview, activity, queue, trustedTools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        projectId = try container.decode(String.self, forKey: .projectId)
        role = try container.decode(String.self, forKey: .role)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        status = try container.decodeIfPresent(AgentStatus.self, forKey: .status) ?? .idle
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        lastActivityAt = try container.decodeIfPresent(Date.self, forKey: .lastActivityAt) ?? createdAt
        preview = try container.decodeIfPresent(String.self, forKey: .preview)
        activity = try container.decodeIfPresent(String.self, forKey: .activity)
        queue = try container.decodeIfPresent([QueuedMessage].self, forKey: .queue) ?? []
        trustedTools = try container.decodeIfPresent([String].self, forKey: .trustedTools) ?? []
    }
}

extension Agent {
    static let nameMaxLength = 40

    static func byUrgency(_ first: Agent, _ second: Agent) -> Bool {
        if first.status.urgency != second.status.urgency { return first.status.urgency < second.status.urgency }
        if first.lastActivityAt != second.lastActivityAt { return first.lastActivityAt > second.lastActivityAt }
        return first.id < second.id
    }

    static func byCreation(_ first: Agent, _ second: Agent) -> Bool {
        if first.createdAt != second.createdAt { return first.createdAt < second.createdAt }
        return first.id < second.id
    }
}
