import SwiftUI

struct DeleteAgentConfirmation: ViewModifier {
    @Binding var agent: Agent?

    @Environment(AppStore.self) private var store

    private var isPresented: Binding<Bool> {
        Binding(get: { agent != nil }, set: { shown in
            if !shown { agent = nil }
        })
    }

    func body(content: Content) -> some View {
        content.confirmationDialog("Delete this agent?", isPresented: isPresented, titleVisibility: .visible, presenting: agent) { agent in
            Button("Delete \(agent.name)", role: .destructive) { delete(agent) }
            Button("Cancel", role: .cancel) {}
        } message: { agent in
            Text("\(agent.name) and its conversation are removed from Switchboard. This cannot be undone.")
        }
    }

    private func delete(_ agent: Agent) {
        Task {
            do {
                try await store.deleteAgent(id: agent.id)
            } catch {
                store.notice = error.localizedDescription
            }
        }
    }
}

extension View {
    func deleteAgentConfirmation(for agent: Binding<Agent?>) -> some View {
        modifier(DeleteAgentConfirmation(agent: agent))
    }
}
