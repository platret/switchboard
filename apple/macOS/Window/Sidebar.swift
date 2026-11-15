import SwiftUI

struct Sidebar: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store

    private var agents: [Agent] {
        store.selectedProject.map { store.agents(in: $0.id) } ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                HoverRow(isSelected: store.selectedAgentId == nil) {
                    store.selectAgent(nil)
                } content: {
                    OverviewEntry()
                }
                if let project = store.selectedProject {
                    Text("Agents in \(project.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(Array(agents.enumerated()), id: \.element.id) { index, agent in
                        row(for: agent, index: index)
                    }
                    if agents.isEmpty { hint("No agents here yet. Create one to start a conversation.") }
                } else if store.isReady {
                    hint("No project yet. Edit projects.json in the Switchboard folder so it lists a folder that exists, then restart the host.")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .safeAreaInset(edge: .top, spacing: 0) { ProjectPicker() }
        .safeAreaInset(edge: .bottom, spacing: 0) { SidebarFooter() }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(8)
    }

    private func row(for agent: Agent, index: Int) -> some View {
        HoverRow(isSelected: store.selectedAgentId == agent.id) {
            store.selectAgent(agent.id)
        } content: {
            AgentRow(agent: agent)
        }
        .help(index < 9 ? "Command \(index + 1) opens \(agent.name)" : agent.name)
        .contextMenu {
            Button("Rename") { session.renaming = agent }
            Button("Stop") { store.stop(agentId: agent.id) }.disabled(!agent.status.isBusy)
            Divider()
            Button("Delete", role: .destructive) { session.deleting = agent }
        }
    }
}
