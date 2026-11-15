import Foundation

struct Project: Hashable, Identifiable, Sendable {
    let id: String
    var name: String
    var path: String
    var additionalDirectories: [String] = []
    var agents: [String] = []
}

extension Project: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, name, path, additionalDirectories, agents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decodeIfPresent(String.self, forKey: .path) ?? ""
        additionalDirectories = try container.decodeIfPresent([String].self, forKey: .additionalDirectories) ?? []
        agents = try container.decodeIfPresent([String].self, forKey: .agents) ?? []
    }
}
