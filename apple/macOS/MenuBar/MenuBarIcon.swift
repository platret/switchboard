import SwiftUI

struct MenuBarIcon: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    private var glyph: MenuBarGlyph {
        if !store.isReady || store.connection != .connected { return .offline }
        if !store.approvals.isEmpty || store.waitingCount > 0 { return .waiting }
        if store.workingCount > 0 { return .working }
        return store.errorCount > 0 ? .error : .idle
    }

    private var spoken: String {
        store.isReady ? "Switchboard, \(store.summary)" : "Switchboard, \(store.connection.label)"
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(nsImage: glyph.image)
            if !store.approvals.isEmpty { Text(String(store.approvals.count)) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .onAppear { session.openMainWindow = { openWindow(id: MacSession.mainWindowID) } }
    }
}
