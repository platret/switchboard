import SwiftUI

struct ChatScreen: View {
    let agent: Agent
    var showsApprovals = true

    @Environment(AppStore.self) private var store
    @State private var sends = 0

    private var isLoaded: Bool {
        store.isHistoryLoaded(agent.id)
    }

    private var hasMessages: Bool {
        !store.items(for: agent.id).isEmpty || !store.drafts(for: agent.id).isEmpty
    }

    private var isEmpty: Bool {
        let hasApprovals = showsApprovals && !store.approvals(for: agent.id).isEmpty
        return !hasMessages && !hasApprovals
    }

    private var historyRequest: String {
        "\(agent.id) \(store.connection == .connected && store.isReady && !isLoaded)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ActivityLine(agent: agent)
            messages.frame(maxWidth: .infinity, maxHeight: .infinity)
            Composer(agent: agent) { sends += 1 }
        }
        .id(agent.id)
        .task(id: historyRequest) {
            if store.connection == .connected, store.isReady, !isLoaded { store.loadHistory(agentId: agent.id) }
        }
    }

    @ViewBuilder private var messages: some View {
        if !isLoaded, !hasMessages {
            ProgressView(store.connection == .connected ? "Loading messages" : store.connection.label)
        } else if isEmpty {
            StarterPrompts(agent: agent, role: store.role(of: agent)) { starter in
                store.send(starter, to: agent.id)
            }
        } else {
            MessageList(agent: agent, showsApprovals: showsApprovals, sends: sends)
        }
    }
}
