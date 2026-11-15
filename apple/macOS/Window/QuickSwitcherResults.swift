import SwiftUI

struct QuickSwitcherResults: View {
    let matches: [Agent]
    let current: String?
    let onOpen: (Agent) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(matches) { agent in
                        HoverRow(isSelected: agent.id == current) {
                            onOpen(agent)
                        } content: {
                            AgentRow(agent: agent, showsProject: true)
                        }
                        .id(agent.id)
                    }
                }
                .padding(8)
            }
            .onChange(of: current) { _, id in
                if let id { proxy.scrollTo(id) }
            }
        }
        .overlay {
            if matches.isEmpty {
                ContentUnavailableView("No agent matches", systemImage: "magnifyingglass", description: Text("Try a name, a role or a project."))
            }
        }
    }
}
