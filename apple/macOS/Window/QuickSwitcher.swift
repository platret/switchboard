import SwiftUI

struct QuickSwitcher: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var highlighted: String?
    @FocusState private var isFocused: Bool

    private var matches: [Agent] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return store.agentsByUrgency }
        return store.agentsByUrgency.filter { agent in
            let fields = [agent.name, store.role(of: agent)?.name ?? agent.role, store.project(of: agent)?.name ?? ""]
            return fields.contains { $0.localizedStandardContains(trimmed) }
        }
    }

    private var current: String? {
        matches.contains { $0.id == highlighted } ? highlighted : matches.first?.id
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                TextField("Find an agent", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isFocused)
                    .onSubmit(openCurrent)
                    .onKeyPress(.downArrow) { move(1) }
                    .onKeyPress(.upArrow) { move(-1) }
            }
            .padding(14)
            Divider()
            QuickSwitcherResults(matches: matches, current: current, onOpen: open)
            Divider()
            HStack {
                Text("Arrow keys move, Return opens").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            .padding(12)
        }
        .frame(width: 520, height: 440)
        .onAppear { isFocused = true }
    }

    private func move(_ step: Int) -> KeyPress.Result {
        guard !matches.isEmpty else { return .handled }
        let index = matches.firstIndex { $0.id == current } ?? 0
        highlighted = matches[min(max(index + step, 0), matches.count - 1)].id
        return .handled
    }

    private func openCurrent() {
        guard let agent = matches.first(where: { $0.id == current }) else { return }
        open(agent)
    }

    private func open(_ agent: Agent) {
        store.openAgent(agent)
        dismiss()
    }
}
