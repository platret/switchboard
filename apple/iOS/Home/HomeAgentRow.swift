import SwiftUI

struct HomeAgentRow: View {
    let agent: Agent
    let onRename: () -> Void
    let onDelete: () -> Void

    @Environment(AppStore.self) private var store

    var body: some View {
        Button {
            store.openAgent(agent)
        } label: {
            AgentRow(agent: agent)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            Button("Rename", systemImage: "pencil", action: onRename).tint(Palette.cobalt)
        }
        .swipeActions(edge: .leading) {
            if agent.status.isBusy {
                Button("Stop", systemImage: "stop.fill") { store.stop(agentId: agent.id) }.tint(.gray)
            }
        }
        .contextMenu {
            Button("Rename", systemImage: "pencil", action: onRename)
            if agent.status.isBusy {
                Button("Stop", systemImage: "stop.fill") { store.stop(agentId: agent.id) }
            }
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
        .accessibilityHint("Opens the chat")
    }
}
