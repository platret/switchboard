import SwiftUI

struct MenuBarContent: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @State private var measured: CGFloat?

    private static let maxListHeight: CGFloat = 460

    private var estimate: CGFloat {
        CGFloat(store.agents.count) * 48 + CGFloat(store.approvals.count) * 130 + 60
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !store.isReady {
                        ConnectionStatusRow().padding(.horizontal, 6)
                    }
                    if !store.approvals.isEmpty {
                        MenuBarSection(title: "Needs approval") {
                            ApprovalList(style: .compact) { agent in session.open(agent) }
                        }
                    }
                    if store.isReady {
                        MenuBarSection(title: "Agents") { MenuBarAgents() }
                    }
                }
                .padding(10)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    measured = height
                }
            }
            .frame(height: min(measured ?? estimate, MenuBarContent.maxListHeight))
            Divider()
            MenuBarFooter()
        }
        .frame(width: 372)
        .onAppear { session.openMainWindow = { openWindow(id: MacSession.mainWindowID) } }
    }
}
