import Foundation

extension Project: Encodable {
    private enum EncodingKeys: String, CodingKey {
        case id, name, path, additionalDirectories, agents
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encode(additionalDirectories, forKey: .additionalDirectories)
        try container.encode(agents, forKey: .agents)
    }
}
