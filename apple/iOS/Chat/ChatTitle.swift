import SwiftUI

struct ChatTitle: View {
    let agent: Agent

    @Environment(AppStore.self) private var store

    private var role: String {
        store.role(of: agent)?.name ?? agent.role
    }

    var body: some View {
        HStack(spacing: 8) {
            StatusLamp(status: agent.status, size: 11)
            VStack(alignment: .leading, spacing: 0) {
                Text(agent.name).font(.headline).lineLimit(1)
                Text(role).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(agent.name), \(role), \(agent.status.label)")
        .accessibilityAddTraits(.isHeader)
    }
}
