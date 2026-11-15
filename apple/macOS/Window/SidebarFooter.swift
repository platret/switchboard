import SwiftUI

struct SidebarFooter: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @Environment(HostController.self) private var host

    private var symbol: String {
        switch store.connection {
        case .connected: "checkmark.circle.fill"
        case .connecting, .reconnecting: "arrow.triangle.2.circlepath"
        case .notConfigured: "circle.dashed"
        case .tokenRejected: "xmark.octagon.fill"
        }
    }

    private var tint: Color {
        switch store.connection {
        case .connected: .green
        case .tokenRejected: Palette.danger
        default: .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                session.newAgent()
            } label: {
                Label("New agent", systemImage: "plus").frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .disabled(!store.isReady || store.selectedProject == nil)
            .help("Create an agent in this project (Command N)")
            HStack(spacing: 8) {
                SettingsLink {
                    HStack(spacing: 6) {
                        Image(systemName: symbol).foregroundStyle(tint)
                        Text("\(store.connection.label), \(host.state.label.lowercased())").lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Open the connection and host settings")
                Spacer(minLength: 0)
                Button {
                    session.pairPhone()
                } label: {
                    Image(systemName: "iphone").frame(width: 26, height: 22).contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Pair iPhone")
                .help("Show the pairing code for the iPhone app")
            }
        }
        .padding(12)
        .overlay(alignment: .top) { Divider() }
    }
}
