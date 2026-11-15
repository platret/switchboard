import SwiftUI

struct DetailView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if store.needsSetup {
            SetupView()
        } else if !store.isReady {
            ConnectingView()
        } else if let agent = store.selectedAgent {
            AgentDetail(agent: agent)
        } else {
            OverviewDetail()
        }
    }
}
