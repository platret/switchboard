import SwiftUI

struct ConnectionFields: View {
    var allowsForgetting = false

    @Environment(AppStore.self) private var store
    @State private var host = ""
    @State private var token = ""
    @State private var failure: String?

    private var canConnect: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Section {
            TextField("Host address", text: $host, prompt: Text("http://100.64.0.1:4317"))
                .autocorrectionDisabled()
                .onAppear { host = store.settings.hostURL }
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif
            SecureField("Access token", text: $token, prompt: Text("Access token"))
                .onSubmit(connect)
        } header: {
            SectionTitle("Host")
        } footer: {
            Text("The address of the Switchboard host on your Mac and its access token. A pairing link pasted into the address field fills in both. Leave the token empty to keep the one that is already saved.")
        }
        Section {
            Button("Connect", action: connect).disabled(!canConnect)
            ConnectionStatusRow()
            if let failure {
                Label(failure, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Palette.danger)
            }
            if allowsForgetting, store.connection != .notConfigured {
                Button("Forget this host", role: .destructive) { store.forgetConnection() }
            }
        }
    }

    private func connect() {
        failure = nil
        if let link = PairingLink(string: host) {
            store.pair(with: link)
            host = link.endpoint.displayString
            token = ""
            return
        }
        guard let endpoint = HostEndpoint(string: host) else {
            failure = ClientError.invalidHost.errorDescription
            return
        }
        if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.settings.hostURL = endpoint.displayString
            store.connect()
        } else {
            do {
                try store.saveConnection(host: host, token: token)
            } catch {
                failure = error.localizedDescription
            }
        }
        host = endpoint.displayString
        token = ""
    }
}
