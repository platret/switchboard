import SwiftUI

struct MessageList: View {
    let agent: Agent
    var showsApprovals = true
    var sends = 0

    @Environment(AppStore.self) private var store
    @State private var pin = MessageListPin()

    private static let bottom = "message-list-bottom"

    var body: some View {
        let items = store.items(for: agent.id)
        let drafts = store.drafts(for: agent.id)
        let approvals = showsApprovals ? store.approvals(for: agent.id) : []
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(ChatEntry.thread(from: items)) { entry in
                        ChatEntryView(entry: entry)
                    }
                    ForEach(drafts) { draft in
                        DraftMessage(draft: draft)
                    }
                    ForEach(approvals) { approval in
                        ApprovalCard(approval: approval)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id(MessageList.bottom)
                        .onAppear { pin.attach() }
                        .onDisappear { pin.release() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: Surface.readingWidth)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: MessageListMarker(items: items, drafts: drafts, approvals: approvals)) { previous, marker in
                guard pin.isPinned else { return }
                withAnimation(marker.addsRow(after: previous) ? .easeOut(duration: 0.2) : nil) {
                    proxy.scrollTo(MessageList.bottom, anchor: .bottom)
                }
            }
            .onChange(of: sends) { _, _ in
                pin.attach()
                proxy.scrollTo(MessageList.bottom, anchor: .bottom)
            }
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { _ in
                if pin.wasPinnedMomentsAgo { proxy.scrollTo(MessageList.bottom, anchor: .bottom) }
            }
            .overlay(alignment: .bottom) {
                if !pin.isPinned {
                    JumpToLatestButton {
                        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(MessageList.bottom, anchor: .bottom) }
                    }
                }
            }
            .animation(.easeOut(duration: 0.15), value: pin.isPinned)
        }
    }
}
