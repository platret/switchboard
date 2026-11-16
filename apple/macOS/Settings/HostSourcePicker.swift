import SwiftUI

struct HostSourcePicker: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @Environment(HostController.self) private var host

    private var selection: Binding<HostSourceKind> {
        Binding(get: { host.source?.kind ?? .repo }, set: { kind in
            guard kind != host.source?.kind else { return }
            store.settings.hostSource = kind.rawValue
            Task { await switchSource() }
        })
    }

    var body: some View {
        Picker("Run the host from", selection: selection) {
            Text("Switchboard itself").tag(HostSourceKind.bundled)
            Text("Your Switchboard clone").tag(HostSourceKind.repo)
        }
        .disabled(host.state == .starting || host.state == .stopping)
    }

    private func switchSource() async {
        let wasOwned = host.ownsProcess
        if wasOwned { await host.stop() }
        await host.readConfiguration()
        if case .bundled(_, let home) = host.source {
            try? await Task.detached { try SwitchboardHome.prepare(home) }.value
        }
        if wasOwned { await host.start() } else { await host.refresh() }
        guard host.isRunning else { return }
        if host.source?.kind == .bundled { session.reconnectIfNeeded() } else { store.connect() }
    }
}
