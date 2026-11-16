import SwiftUI

struct SetupView: View {
    @Environment(HostController.self) private var host

    private var note: String {
        host.source?.kind == .bundled
            ? "Switchboard connects by itself once the host runs."
            : "Switchboard connects by itself once the host runs and the repo folder in Settings holds its .env file."
    }

    var body: some View {
        Form {
            Section {
                HostStatusRow()
                HostControls()
            } header: {
                SectionTitle("This Mac")
            } footer: {
                Text(note)
            }
            ConnectionFields()
        }
        .formStyle(.grouped)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Switchboard")
        .navigationSubtitle("Connect to a host")
    }
}
