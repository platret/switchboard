import Foundation

struct Role: Hashable, Identifiable, Sendable {
    let id: String
    var name: String
    var description: String = ""
    var tools: [String] = []
    var model: String?
    var starters: [String] = []
}

extension Role: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, name, description, tools, model, starters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        tools = try container.decodeIfPresent([String].self, forKey: .tools) ?? []
        model = try container.decodeIfPresent(String.self, forKey: .model)
        starters = try container.decodeIfPresent([String].self, forKey: .starters) ?? []
    }
}
