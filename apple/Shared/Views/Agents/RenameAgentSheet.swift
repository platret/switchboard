import SwiftUI

struct RenameAgentSheet: View {
    let agent: Agent

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isSaving = false
    @State private var failure: String?

    private var canSave: Bool {
        AgentNaming.isValid(name) && name.trimmingCharacters(in: .whitespacesAndNewlines) != agent.name
    }

    var body: some View {
        SheetScaffold(title: "Rename agent", confirmTitle: "Save", canConfirm: canSave, isWorking: isSaving, failure: failure, height: 210, onConfirm: save) {
            Section {
                AgentNameField(name: $name, onSubmit: save)
            } header: {
                SectionTitle("Agent")
            }
        }
        .onAppear { name = agent.name }
        .presentationDetents([.medium])
    }

    private func save() {
        guard canSave, !isSaving else { return }
        isSaving = true
        failure = nil
        Task {
            do {
                try await store.renameAgent(id: agent.id, name: name)
                dismiss()
            } catch {
                failure = error.localizedDescription
            }
            isSaving = false
        }
    }
}
