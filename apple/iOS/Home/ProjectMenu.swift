import SwiftUI

struct ProjectMenu: View {
    @Environment(AppStore.self) private var store

    private var selection: Binding<String?> {
        Binding(get: { store.selectedProjectId }, set: { store.selectProject($0) })
    }

    private var name: String {
        store.selectedProject?.name ?? "Switchboard"
    }

    var body: some View {
        Menu {
            Picker("Project", selection: selection) {
                ForEach(store.projects) { project in
                    Text(project.name).tag(Optional(project.id))
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(name).font(.headline).foregroundStyle(Color.primary).lineLimit(1)
                Image(systemName: "chevron.down").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Project, \(name)")
        .accessibilityHint("Switches to another project")
    }
}
