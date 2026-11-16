import SwiftUI

struct HostSettings: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @Environment(HostController.self) private var host

    private var footer: String {
        let summary = host.source?.summary ?? "Choose your Switchboard clone in Settings, Connection."
        return "\(summary) It never starts a second host when one already answers."
    }

    var body: some View {
        @Bindable var settings = store.settings
        Form {
            Section {
                HostStatusRow()
                HStack {
                    HostControls()
                    Button("Open web app") { session.openWebApp() }.disabled(!host.isRunning)
                }
                if host.bundled != nil, !settings.repoFolder.isEmpty {
                    HostSourcePicker()
                }
                Toggle("Start the host when Switchboard opens", isOn: $settings.startsHostOnLaunch)
            } header: {
                SectionTitle("Host")
            } footer: {
                Text(footer)
            }
            Section {
                HostLogView()
            } header: {
                SectionTitle("Log")
            }
        }
        .formStyle(.grouped)
    }
}
