import SwiftUI

struct MainView: View {
    @Environment(AppStore.self) private var store
    @State private var path: [AppRoute] = []

    var body: some View {
        VStack(spacing: 0) {
            NavigationStack(path: $path) {
                HomeScreen()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .agent(let agentId): AgentChatScreen(agentId: agentId)
                        case .overview: OverviewScreen()
                        case .settings: SettingsScreen()
                        }
                    }
            }
            if store.notice != nil {
                NoticeBanner().padding(.horizontal, 12).padding(.vertical, 8).background(.bar)
            }
            ApprovalTray()
        }
        .animation(.snappy(duration: 0.3), value: store.approvals.map(\.id))
        .animation(.snappy(duration: 0.3), value: store.notice)
        .sensoryFeedback(trigger: store.approvals.map(\.id)) { previous, current in
            current.count > previous.count ? .warning : nil
        }
        .onAppear { show(store.selectedAgentId) }
        .onChange(of: store.selectedAgentId) { _, agentId in show(agentId) }
        .onChange(of: path) { _, path in
            let open = path.last?.agentId
            if store.selectedAgentId != open { store.selectAgent(open) }
        }
    }

    private func show(_ agentId: String?) {
        let open = path.last?.agentId
        guard agentId != open else { return }
        if open != nil { path.removeLast() }
        if let agentId { path.append(.agent(agentId)) }
    }
}
