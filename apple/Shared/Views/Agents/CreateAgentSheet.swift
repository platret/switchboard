import SwiftUI

struct CreateAgentSheet: View {
    let project: Project

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var roleId = ""
    @State private var isSaving = false
    @State private var failure: String?

    private var roles: [Role] {
        let scoped = store.roles(for: project)
        return scoped.isEmpty ? store.roles : scoped
    }

    private var takenNames: [String] {
        store.agents(in: project.id).map(\.name)
    }

    private var canCreate: Bool {
        AgentNaming.isValid(name) && roles.contains { $0.id == roleId }
    }

    var body: some View {
        SheetScaffold(title: "New agent", confirmTitle: "Create", canConfirm: canCreate, isWorking: isSaving, failure: failure, height: 460, onConfirm: create) {
            Section {
                LabeledContent("Project", value: project.name)
                AgentNameField(name: $name, onSubmit: create)
            } header: {
                SectionTitle("Agent")
            }
            Section {
                ForEach(roles) { role in
                    RoleOption(role: role, isSelected: role.id == roleId) { select(role) }
                }
            } header: {
                SectionTitle("Role")
            } footer: {
                if roles.isEmpty { Text("This project has no roles. Add some to projects.json on the host.") }
            }
        }
        .onAppear {
            if roleId.isEmpty, let first = roles.first { select(first) }
        }
    }

    private func select(_ role: Role) {
        let previous = roles.first { $0.id == roleId }
        let wasSuggested = previous.map { name == AgentNaming.suggestion(for: $0, taken: takenNames) } ?? false
        if name.isEmpty || wasSuggested { name = AgentNaming.suggestion(for: role, taken: takenNames) }
        roleId = role.id
    }

    private func create() {
        guard canCreate, !isSaving else { return }
        isSaving = true
        failure = nil
        Task {
            do {
                try await store.createAgent(projectId: project.id, role: roleId, name: name)
                dismiss()
            } catch {
                failure = error.localizedDescription
            }
            isSaving = false
        }
    }
}
