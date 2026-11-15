import Foundation

struct History: Hashable, Sendable {
    var items: [ChatItem] = []
    var drafts: [ChatDraft] = []
}

extension History: Decodable {
    private enum CodingKeys: String, CodingKey {
        case items, drafts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.lossyArray(ChatItem.self, forKey: .items)
        drafts = try container.lossyArray(ChatDraft.self, forKey: .drafts)
    }
}
