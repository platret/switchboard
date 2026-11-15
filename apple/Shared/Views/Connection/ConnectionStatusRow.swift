import SwiftUI

struct ConnectionStatusRow: View {
    @Environment(AppStore.self) private var store

    private var explanation: String {
        if store.isWaitingForFolderAccess { return "Waiting for permission to read the repo folder. Choose Allow in the macOS prompt." }
        switch store.connection {
        case .notConfigured: return "Enter the host address and the access token to connect."
        case .connecting: return "Reaching \(store.settings.hostURL)"
        case .connected: return store.settings.hostURL
        case .reconnecting: return "The host does not answer. Trying again on its own."
        case .tokenRejected: return "The host refused this token. Check SWITCHBOARD_TOKEN in the .env file of the host."
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            icon.frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.connection.label)
                Text(explanation).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var icon: some View {
        switch store.connection {
        case .notConfigured: Image(systemName: "circle.dashed").foregroundStyle(.secondary)
        case .connecting, .reconnecting: ProgressView().controlSize(.small)
        case .connected: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .tokenRejected: Image(systemName: "xmark.octagon.fill").foregroundStyle(Palette.danger)
        }
    }
}
