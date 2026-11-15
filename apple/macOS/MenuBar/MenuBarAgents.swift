import SwiftUI

struct MenuBarAgents: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 1) {
            ForEach(store.agentsByUrgency) { agent in
                HoverRow {
                    session.open(agent)
                } content: {
                    MenuBarAgentRow(agent: agent)
                }
                .accessibilityHint("Opens the chat in the main window")
            }
            if store.agents.isEmpty {
                Text("No agents yet. Create one in the main window.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
            }
        }
    }
}
