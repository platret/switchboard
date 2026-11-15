import SwiftUI

struct MainWindow: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var session = session
        NavigationSplitView {
            Sidebar().navigationSplitViewColumnWidth(min: 250, ideal: 290, max: 380)
        } detail: {
            HStack(spacing: 0) {
                DetailView().frame(maxWidth: .infinity, maxHeight: .infinity)
                if !store.approvals.isEmpty {
                    Divider()
                    ApprovalPanel().transition(.move(edge: .trailing))
                }
            }
            .animation(.snappy, value: store.approvals.isEmpty)
        }
        .overlay(alignment: .top) {
            NoticeBanner().frame(maxWidth: 520).padding(.top, 8).padding(.horizontal, 16)
        }
        .sheet(isPresented: $session.showsCreate) {
            if let project = store.selectedProject { CreateAgentSheet(project: project).session(session) }
        }
        .sheet(isPresented: $session.showsSwitcher) { QuickSwitcher().session(session) }
        .sheet(isPresented: $session.showsPairing) { PairingSheet().session(session) }
        .sheet(item: $session.renaming) { agent in RenameAgentSheet(agent: agent).session(session) }
        .deleteAgentConfirmation(for: $session.deleting)
        .frame(minWidth: 900, idealWidth: 1160, minHeight: 560, idealHeight: 760)
        .focusedSceneValue(\.agents, FocusedAgents(shortcuts: session.shortcutAgents, selected: store.selectedAgent))
        .onAppear { session.openMainWindow = { openWindow(id: MacSession.mainWindowID) } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshConnection() }
        }
    }
}
