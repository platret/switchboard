import SwiftUI

struct HostSettings: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @Environment(HostController.self) private var host

    var body: some View {
        @Bindable var settings = store.settings
        Form {
            Section {
                HostStatusRow()
                HStack {
                    HostControls()
                    Button("Open web app") { session.openWebApp() }.disabled(!host.isRunning)
                }
                Toggle("Start the host when Switchboard opens", isOn: $settings.startsHostOnLaunch)
            } header: {
                SectionTitle("Host")
            } footer: {
                Text("Switchboard runs pnpm start in the repo folder and never starts a second host when one already answers.")
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
