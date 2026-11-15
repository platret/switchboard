import SwiftUI

struct AgentList: View {
    @Environment(AppStore.self) private var store
    @State private var renaming: Agent?
    @State private var deleting: Agent?

    private var agents: [Agent] {
        guard let projectId = store.selectedProjectId else { return [] }
        return store.agents(in: projectId).sorted(by: Agent.byUrgency)
    }

    var body: some View {
        List {
            if store.connection != .connected {
                Section { ConnectionStatusRow() }
            }
            Section {
                NavigationLink(value: AppRoute.overview) { AllAgentsRow() }
            }
            Section {
                ForEach(agents) { agent in
                    HomeAgentRow(agent: agent, onRename: { renaming = agent }, onDelete: { deleting = agent })
                }
                if agents.isEmpty { EmptyProjectRow(project: store.selectedProject) }
            } header: {
                SectionTitle(store.selectedProject.map { "Agents in \($0.name)" } ?? "Agents")
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 8, for: .scrollContent)
        .refreshable {
            store.connect()
            try? await Task.sleep(for: .milliseconds(700))
        }
        .sheet(item: $renaming) { agent in
            RenameAgentSheet(agent: agent)
        }
        .deleteAgentConfirmation(for: $deleting)
    }
}
