import Foundation

struct Approval: Hashable, Identifiable, Sendable {
    static let turnTrustTools: Set<String> = ["Edit", "Write", "NotebookEdit"]

    let id: String
    let agentId: String
    var toolName: String
    var summary: String = ""
    var input: JSONValue = .null
    var createdAt: Date = .distantPast
    var expiresAt: Date = .distantFuture
    var turnTrust: Bool?

    var supportsTurnScope: Bool {
        turnTrust ?? Approval.turnTrustTools.contains(toolName)
    }

    func remaining(at now: Date = Date()) -> TimeInterval {
        max(0, expiresAt.timeIntervalSince(now))
    }
}

extension Approval: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, agentId, toolName, summary, input, createdAt, expiresAt, turnTrust
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        agentId = try container.decode(String.self, forKey: .agentId)
        toolName = try container.decode(String.self, forKey: .toolName)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        input = try container.decodeIfPresent(JSONValue.self, forKey: .input) ?? .null
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt) ?? .distantFuture
        turnTrust = try container.decodeIfPresent(Bool.self, forKey: .turnTrust)
    }
}
