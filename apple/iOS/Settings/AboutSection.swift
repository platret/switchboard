import SwiftUI

struct AboutSection: View {
    @Environment(AppStore.self) private var store

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Section {
            LabeledContent("Version", value: version)
            if let address = store.hostInfo?.tailscaleUrl {
                LabeledContent("Tailscale address", value: address)
            }
            if store.isReady {
                LabeledContent("Projects", value: "\(store.projects.count)")
                LabeledContent("Agents", value: "\(store.agents.count)")
            }
        } header: {
            SectionTitle("About")
        } footer: {
            Text("Switchboard is your control center for Claude agents. The host runs on your Mac and this app reaches it over your tailnet.")
        }
    }
}
