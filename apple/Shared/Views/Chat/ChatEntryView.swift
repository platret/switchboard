import SwiftUI

struct ChatEntryView: View {
    let entry: ChatEntry

    var body: some View {
        switch entry {
        case .tools(_, let calls):
            ToolGroup(calls: calls)
        case .item(let item):
            switch item.content {
            case .text(let text) where item.role == .user:
                UserBubble(text: text)
            case .text(let text) where item.role == .assistant:
                MarkdownView(text: text)
            case .text(let text), .notice(let text):
                NoticeRow(text: text)
            case .error(let text):
                ErrorRow(text: text)
            case .tool, .unknown:
                EmptyView()
            }
        }
    }
}
