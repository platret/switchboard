import Foundation

struct ToolCall: Hashable, Sendable {
    let toolUseId: String
    var name: String
    var summary: String = ""
    var input: JSONValue = .null
    var status: ToolStatus = .done
    var result: String?
}

extension ToolCall: Decodable {
    private enum CodingKeys: String, CodingKey {
        case toolUseId, name, summary, input, status, result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toolUseId = try container.decode(String.self, forKey: .toolUseId)
        name = try container.decode(String.self, forKey: .name)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        input = try container.decodeIfPresent(JSONValue.self, forKey: .input) ?? .null
        status = try container.decodeIfPresent(ToolStatus.self, forKey: .status) ?? .done
        result = try container.decodeIfPresent(String.self, forKey: .result)
    }
}
