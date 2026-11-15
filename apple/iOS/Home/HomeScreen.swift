import SwiftUI

struct HomeScreen: View {
    @Environment(AppStore.self) private var store
    @State private var showsCreate = false

    var body: some View {
        Group {
            if store.isReady {
                AgentList()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        NewAgentBar(isEnabled: store.selectedProject != nil) { showsCreate = true }
                    }
            } else {
                ConnectingView()
            }
        }
        .navigationTitle(store.selectedProject?.name ?? "Switchboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if store.isReady { ProjectMenu() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showsCreate) {
            if let project = store.selectedProject { CreateAgentSheet(project: project) }
        }
    }
}
