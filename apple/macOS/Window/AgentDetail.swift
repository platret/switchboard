import SwiftUI

struct AgentDetail: View {
    let agent: Agent

    @Environment(AppStore.self) private var store

    private var subtitle: String {
        let role = store.role(of: agent)?.name ?? agent.role
        guard let project = store.project(of: agent) else { return role }
        return "\(role) in \(project.name)"
    }

    var body: some View {
        ChatScreen(agent: agent, showsApprovals: false)
            .background(Color(nsColor: .textBackgroundColor))
            .navigationTitle(agent.name)
            .navigationSubtitle(subtitle)
            .toolbar { AgentToolbar(agent: agent) }
    }
}
