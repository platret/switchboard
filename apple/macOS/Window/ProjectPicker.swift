import SwiftUI

struct ProjectPicker: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store

    private var selection: Binding<String?> {
        Binding(get: { store.selectedProjectId }, set: { store.selectProject($0) })
    }

    var body: some View {
        HStack(spacing: 8) {
            Picker("Project", selection: selection) {
                ForEach(store.projects) { project in
                    Text(project.name).tag(Optional(project.id))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
            .disabled(store.projects.isEmpty)
            .help(store.selectedProject?.path ?? "Projects come from projects.json on the host")
            .accessibilityLabel("Project")
            Spacer(minLength: 0)
            Button("Find agent", systemImage: "magnifyingglass") { session.quickSwitch() }
                .labelStyle(.iconOnly)
                .help("Find an agent in any project (Command K)")
        }
        .controlSize(.large)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
}
