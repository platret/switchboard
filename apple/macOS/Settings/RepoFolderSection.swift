import AppKit
import SwiftUI

struct RepoFolderSection: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store
    @State private var message: String?
    @State private var didFail = false

    var body: some View {
        Section {
            LabeledContent("Folder") {
                HStack(spacing: 8) {
                    Text(store.settings.repoFolder.isEmpty ? "Not set" : store.settings.repoFolder)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                        .help(store.settings.repoFolder)
                    Button("Choose", action: chooseFolder)
                }
            }
            Button("Use the token from the repo .env", action: adoptToken)
            if let message {
                Label(message, systemImage: didFail ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(didFail ? Palette.danger : Color.secondary)
            }
        } header: {
            SectionTitle("Repo folder")
        } footer: {
            Text("The folder of the Switchboard repo. The app reads SWITCHBOARD_TOKEN from its .env file and starts the host from there.")
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: (store.settings.repoFolder as NSString).expandingTildeInPath)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.settings.repoFolder = url.path
        message = nil
        Task { await session.host.refresh() }
    }

    private func adoptToken() {
        let folder = store.settings.repoFolder
        Task {
            let token = await Task.detached { EnvFile.token(inFolder: folder) }.value
            guard let token else { return report("No SWITCHBOARD_TOKEN in the .env file of that folder. Start the host once so it creates one.", failed: true) }
            do {
                let host = store.settings.hostURL.isEmpty ? HostEndpoint.localhost : store.settings.hostURL
                try store.saveConnection(host: host, token: token)
                report("Token saved. Connecting.", failed: false)
            } catch {
                report(error.localizedDescription, failed: true)
            }
        }
    }

    private func report(_ text: String, failed: Bool) {
        message = text
        didFail = failed
    }
}
