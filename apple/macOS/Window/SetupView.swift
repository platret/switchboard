import SwiftUI

struct SetupView: View {
    var body: some View {
        Form {
            Section {
                HostStatusRow()
                HostControls()
            } header: {
                SectionTitle("This Mac")
            } footer: {
                Text("Switchboard connects by itself once the host runs and the repo folder in Settings holds its .env file.")
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
