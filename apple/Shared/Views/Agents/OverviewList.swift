import SwiftUI

struct OverviewList: View {
    var onOpen: ((Agent) -> Void)?

    @Environment(AppStore.self) private var store

    private static let order: [AgentStatus] = AgentStatus.allCases.sorted { $0.urgency < $1.urgency }

    var body: some View {
        let agents = store.agentsByUrgency
        List {
            if !agents.isEmpty {
                Section {
                    OverviewSummary()
                }
            }
            ForEach(OverviewList.order, id: \.self) { status in
                let group = agents.filter { $0.status == status }
                if !group.isEmpty {
                    Section {
                        ForEach(group) { agent in
                            Button {
                                open(agent)
                            } label: {
                                AgentRow(agent: agent, showsProject: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the chat")
                        }
                    } header: {
                        OverviewSectionHeader(status: status, count: group.count)
                    }
                }
            }
        }
        .overlay {
            if agents.isEmpty {
                ContentUnavailableView("No agents yet", systemImage: "person.2", description: Text("Create an agent in a project and it shows up here."))
            }
        }
    }

    private func open(_ agent: Agent) {
        if let onOpen {
            onOpen(agent)
        } else {
            store.openAgent(agent)
        }
    }
}
