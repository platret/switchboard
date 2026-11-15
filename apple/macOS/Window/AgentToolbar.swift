import SwiftUI

struct AgentToolbar: ToolbarContent {
    let agent: Agent

    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store

    var body: some ToolbarContent {
        if #available(macOS 26.0, *) {
            ToolbarItem(placement: .status) { AgentStatusBadge(status: agent.status) }.sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .status) { AgentStatusBadge(status: agent.status) }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button("Stop", systemImage: "stop.fill") { store.stop(agentId: agent.id) }
                .disabled(!agent.status.isBusy)
                .help("Stop the current turn (Command period)")
            Button("Rename", systemImage: "pencil") { session.renaming = agent }
                .help("Rename \(agent.name)")
            Button("Delete", systemImage: "trash") { session.deleting = agent }
                .help("Delete \(agent.name)")
        }
    }
}
