import SwiftUI

struct ProjectsSettings: View {
    @Environment(MacSession.self) private var session
    @Environment(HostController.self) private var host
    @State private var isSaving = false

    private var editor: ProjectsEditor {
        session.projects
    }

    private var note: String {
        guard let location = editor.location else { return "Choose your Switchboard clone in Settings, Connection, to see its projects." }
        if !location.isEditable { return "These come from \(SwitchboardHome.displayPath(location.file.path)) in your clone. Edit that file to change them." }
        return host.ownsProcess ? "Saving restarts the host so it picks up the change." : "The host reads this list when it starts."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProjectsEditorView(editor: editor, listHeight: 330)
            HStack {
                Text(note).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                if editor.readFailure != nil {
                    Button("Reload") { Task { await reload() } }
                } else if editor.isEditable {
                    Button("Revert") { Task { await reload() } }.disabled(!editor.hasChanges || isSaving)
                    Button("Save", action: save).keyboardShortcut(.defaultAction).disabled(!editor.hasChanges || isSaving)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: host.source) { await reload() }
    }

    private func reload() async {
        await editor.load(ProjectsLocation(source: host.source))
    }

    private func save() {
        isSaving = true
        Task {
            let changed = await editor.save()
            if changed, host.ownsProcess { await host.restart() }
            isSaving = false
        }
    }
}
