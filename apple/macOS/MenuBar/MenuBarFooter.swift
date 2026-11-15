import AppKit
import SwiftUI

struct MenuBarFooter: View {
    @Environment(MacSession.self) private var session
    @Environment(HostController.self) private var host

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HostStateIcon(state: host.state)
                Text(host.state.label).font(.callout)
                Spacer(minLength: 8)
                HostControls().controlSize(.small)
            }
            .help(HostStatusRow.detail(for: host))
            HStack(spacing: 14) {
                Button("Open web app") { session.openWebApp() }.disabled(!host.isRunning)
                Button("Pair iPhone") { session.pairPhone() }
                SettingsLink { Text("Settings") }
                Spacer(minLength: 0)
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.link)
            .font(.callout)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
