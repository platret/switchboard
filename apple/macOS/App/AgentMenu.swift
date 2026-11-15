import SwiftUI

struct AgentMenu: View {
    static let shortcutCount = 9

    let session: MacSession
    let focused: FocusedAgents?

    private var hasNoSelection: Bool {
        focused.map { $0.selected == nil } ?? false
    }

    private var isIdle: Bool {
        focused.map { $0.selected?.status.isBusy != true } ?? false
    }

    private var slots: Int {
        min(focused?.shortcuts.count ?? AgentMenu.shortcutCount, AgentMenu.shortcutCount)
    }

    var body: some View {
        Button("Stop") { session.stopSelected() }.keyboardShortcut(".").disabled(isIdle)
        Button("Rename") { session.renameSelected() }.disabled(hasNoSelection)
        Button("Delete") { session.deleteSelected() }.disabled(hasNoSelection)
        Divider()
        Button("All agents") { session.showOverview() }.keyboardShortcut("a", modifiers: [.command, .shift])
        ForEach(0..<slots, id: \.self) { index in
            Button(title(at: index)) { session.openShortcutAgent(at: index) }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")))
        }
    }

    private func title(at index: Int) -> String {
        guard let agents = focused?.shortcuts, agents.indices.contains(index) else { return "Agent \(index + 1)" }
        return agents[index].name
    }
}
