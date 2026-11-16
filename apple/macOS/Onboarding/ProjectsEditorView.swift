import SwiftUI

struct ProjectsEditorView: View {
    let editor: ProjectsEditor
    var listHeight: CGFloat = 272

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity)
    }

    var body: some View {
        VStack(spacing: 12) {
            if editor.isEditable, editor.projects.isEmpty {
                FolderDropZone(isCompact: false, add: add)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(editor.projects) { project in
                            ProjectCard(project: project, editor: editor)
                                .transition(cardTransition)
                        }
                        if editor.projects.isEmpty, editor.readFailure == nil {
                            Text("projects.json lists no projects yet.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                    }
                    .padding(1)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: listHeight)
                .fixedSize(horizontal: false, vertical: true)
                if editor.isEditable {
                    FolderDropZone(isCompact: true, add: add)
                }
            }
            if let failure = editor.readFailure ?? editor.failure {
                Label(failure, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(Palette.danger)
            }
        }
        .animation(reduceMotion ? OnboardingMotion.fade : OnboardingMotion.settle, value: editor.projects.map(\.id))
    }

    private func add(_ folders: [URL]) {
        editor.add(folders)
    }
}
