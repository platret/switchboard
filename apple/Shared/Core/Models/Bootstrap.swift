import Foundation

struct Bootstrap: Hashable, Sendable {
    var projects: [Project] = []
    var roles: [Role] = []
    var agents: [Agent] = []
    var approvals: [Approval] = []
    var host: HostInfo?
}

extension Bootstrap: Decodable {
    private enum CodingKeys: String, CodingKey {
        case projects, roles, agents, approvals, host
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projects = try container.lossyArray(Project.self, forKey: .projects)
        roles = try container.lossyArray(Role.self, forKey: .roles)
        agents = try container.lossyArray(Agent.self, forKey: .agents)
        approvals = try container.lossyArray(Approval.self, forKey: .approvals)
        host = try container.decodeIfPresent(HostInfo.self, forKey: .host)
    }
}
