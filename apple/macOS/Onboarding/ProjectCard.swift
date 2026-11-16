import SwiftUI

struct ProjectCard: View {
    let project: Project
    let editor: ProjectsEditor

    @State private var isHoveringName = false
    @FocusState private var isEditingName: Bool

    private var name: Binding<String> {
        Binding(get: { project.name }, set: { editor.rename(project, to: $0) })
    }

    private var roles: [Role] {
        editor.isEditable ? editor.roles : editor.roles.filter { project.agents.contains($0.id) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.system(size: 18))
                .foregroundStyle(Palette.cobalt)
                .frame(width: 22)
                .padding(.top, 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                VStack(alignment: .leading, spacing: 1) {
                    if editor.isEditable {
                        HStack(spacing: 5) {
                            // The AppKit field draws in textColor, darker than the read-only labels,
                            // so the name shows as a label until someone edits it.
                            Text(project.name.isEmpty ? "Project name" : project.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(project.name.isEmpty ? .tertiary : .primary)
                                .padding(.trailing, 4)
                                .lineLimit(1)
                                .opacity(isEditingName ? 0 : 1)
                                .overlay {
                                    TextField("Project name", text: name)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, weight: .semibold))
                                        .focused($isEditingName)
                                        .opacity(isEditingName ? 1 : 0)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { isEditingName = true }
                                .accessibilityElement(children: isEditingName ? .contain : .ignore)
                                .accessibilityLabel(isEditingName ? "" : "Project name, \(project.name)")
                                .accessibilityAction(named: "Rename") { isEditingName = true }
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .opacity(isHoveringName ? 1 : 0)
                                .accessibilityHidden(true)
                        }
                        .help("Rename")
                        .onHover { isHoveringName = $0 }
                        .animation(OnboardingMotion.fade, value: isHoveringName)
                    } else {
                        Text(project.name).font(.system(size: 13, weight: .semibold))
                    }
                    Text(project.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(project.path)
                }
                FlowLayout(spacing: 4) {
                    ForEach(roles) { role in
                        RoleChip(role: role, isSelected: project.agents.contains(role.id), isEditable: editor.isEditable) {
                            editor.toggle(role: role.id, in: project)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if editor.isEditable {
                Button("Remove \(project.name)", systemImage: "xmark.circle.fill") { editor.remove(project) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
                    .help("Remove this project")
            }
        }
        .padding(12)
        .onboardingCard(corner: 10)
        .accessibilityElement(children: .contain)
    }
}
