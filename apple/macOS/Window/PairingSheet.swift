import SwiftUI

struct PairingSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(HostController.self) private var host
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var token: String?
    @State private var didLoad = false

    private var link: PairingLink? {
        token.flatMap { PairingLink(host: address, port: host.port, token: $0) }
    }

    private var problem: String {
        if !didLoad { return "Reading the access token" }
        if token == nil { return "No access token yet. Start the host once so it creates its .env file." }
        return "Enter the Tailscale address of this Mac, for example 100.64.0.1"
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Pair iPhone").font(.title2.weight(.semibold))
                Text("Open Switchboard on the iPhone and scan this code. Tailscale has to be connected on both devices.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PairingCode(link: link, problem: problem)
            LabeledContent("Address of this Mac") {
                TextField("Address of this Mac", text: $address, prompt: Text("100.64.0.1"))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
            if let link {
                HStack(spacing: 8) {
                    Text(link.string).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                    CopyButton(text: link.string, label: "Copy link")
                }
            }
            Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 420)
        .task {
            address = PairingSheet.suggestedAddress(from: store.hostInfo)
            token = await store.resolveToken()
            didLoad = true
        }
    }

    static func suggestedAddress(from info: HostInfo?) -> String {
        let reported = info?.tailscaleUrl.flatMap { URL(string: $0) }?.host()
        return reported ?? TailscaleAddress.find() ?? ""
    }
}
