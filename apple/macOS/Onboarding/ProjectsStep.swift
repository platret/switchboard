import AppKit
import SwiftUI

struct ProjectsStep: View {
    let editor: ProjectsEditor

    private var subtitle: String {
        editor.isEditable
            ? "Agents work inside these folders. Pick the roles each one gets."
            : "Your clone lists these projects. Agents work inside their folders."
    }

    var body: some View {
        VStack(spacing: 20) {
            OnboardingHeader(title: "Choose projects", subtitle: subtitle)
            Group {
                if editor.didLoad {
                    ProjectsEditorView(editor: editor)
                } else {
                    ProgressView().controlSize(.small).frame(height: 120)
                }
            }
            .reveal(1)
            if let location = editor.location, !location.isEditable {
                HStack(spacing: 8) {
                    Label("Projects come from projects.json in your clone.", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                    Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([location.file]) }
                        .buttonStyle(.plain)
                        .foregroundStyle(Palette.cobalt)
                        .fontWeight(.medium)
                }
                .font(.callout)
                .help(SwitchboardHome.displayPath(location.file.path))
                .reveal(2)
            }
        }
    }
}
