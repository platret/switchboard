import SwiftUI

struct ConnectingView: View {
    @Environment(AppStore.self) private var store
    @Environment(HostController.self) private var host

    private var explanation: String {
        if store.isWaitingForFolderAccess {
            return "macOS is asking whether Switchboard may read the repo folder. Choose Allow in that prompt."
        }
        switch host.state {
        case .unknown: return "Looking for the host on this Mac."
        case .starting: return host.source?.startingDetail ?? "Starting the host."
        case .running: return "Reaching \(store.settings.hostURL)"
        case .stopping: return "The host is stopping."
        case .stopped: return "The host is not running."
        case .failed(let message): return message
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            StatusLamp(status: .working, size: 28)
            Text(store.connection.label).font(.title2.weight(.semibold))
            Text(explanation)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HostControls()
            SettingsLink { Text("Open settings") }.buttonStyle(.link)
        }
        .frame(maxWidth: 420)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Switchboard")
        .navigationSubtitle("")
    }
}
