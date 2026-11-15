import Foundation

enum ChatEntry: Hashable, Identifiable {
    case item(ChatItem)
    case tools(id: String, calls: [ToolCall])

    var id: String {
        switch self {
        case .item(let item): item.id
        case .tools(let id, _): "tools-\(id)"
        }
    }

    static func thread(from items: [ChatItem]) -> [ChatEntry] {
        var entries: [ChatEntry] = []
        for item in items {
            switch item.content {
            case .unknown:
                continue
            case .tool(let call):
                if case .tools(let id, let calls) = entries.last {
                    entries[entries.count - 1] = .tools(id: id, calls: calls + [call])
                } else {
                    entries.append(.tools(id: item.id, calls: [call]))
                }
            case .text, .error, .notice:
                entries.append(.item(item))
            }
        }
        return entries
    }
}
