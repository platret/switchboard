import SwiftUI

struct ConnectingView: View {
    @Environment(AppStore.self) private var store

    private var explanation: String {
        switch store.connection {
        case .reconnecting: "The host at \(store.settings.hostURL) does not answer. Check that your Mac is awake and that Tailscale is connected on both devices."
        default: "Reaching \(store.settings.hostURL)"
        }
    }

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: 14) {
                StatusLamp(status: .working, size: 30)
                Text(store.connection.label)
            }
        } description: {
            Text(explanation)
        } actions: {
            NavigationLink("Connection settings", value: AppRoute.settings)
        }
    }
}
