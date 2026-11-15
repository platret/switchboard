import SwiftUI

struct AgentChatScreen: View {
    let agentId: String

    @Environment(AppStore.self) private var store
    @State private var renaming: Agent?
    @State private var deleting: Agent?

    private var agent: Agent? {
        store.agents[agentId]
    }

    private var sendMarker: SendMarker {
        let sent = store.items(for: agentId).filter { $0.role == .user }.count
        return SendMarker(isLoaded: store.isHistoryLoaded(agentId), count: sent + (agent?.queue.count ?? 0))
    }

    var body: some View {
        Group {
            if let agent {
                ChatScreen(agent: agent, showsApprovals: false)
            } else {
                ContentUnavailableView("This agent is gone", systemImage: "person.slash", description: Text("It was deleted on another device."))
            }
        }
        .navigationTitle(agent?.name ?? "Agent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let agent {
                ToolbarItem(placement: .principal) { ChatTitle(agent: agent) }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Agent actions", systemImage: "ellipsis") {
                        Button("Rename", systemImage: "pencil") { renaming = agent }
                        Button("Delete", systemImage: "trash", role: .destructive) { deleting = agent }
                    }
                }
            }
        }
        .sheet(item: $renaming) { agent in
            RenameAgentSheet(agent: agent)
        }
        .deleteAgentConfirmation(for: $deleting)
        .sensoryFeedback(trigger: sendMarker) { previous, current in
            current.follows(previous) ? .impact(weight: .light) : nil
        }
    }
}
