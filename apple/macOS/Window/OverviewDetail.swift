import SwiftUI

struct OverviewDetail: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        OverviewList { agent in store.openAgent(agent) }
            .listStyle(.inset)
            .navigationTitle("All agents")
            .navigationSubtitle(store.agents.isEmpty ? "" : store.summary)
    }
}
