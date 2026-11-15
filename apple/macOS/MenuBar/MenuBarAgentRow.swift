import SwiftUI

struct MenuBarAgentRow: View {
    let agent: Agent

    @Environment(AppStore.self) private var store

    private var statusColor: Color {
        agent.status == .idle ? .secondary : Palette.lamp(agent.status)
    }

    private var spoken: String {
        var parts = [agent.name, agent.status.label]
        if let project = store.project(of: agent) { parts.insert(project.name, at: 1) }
        if agent.status != .waiting { parts.append(agent.statusLine) }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 10) {
            StatusLamp(status: agent.status)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(agent.name).fontWeight(.medium).lineLimit(1)
                    if let project = store.project(of: agent) {
                        Text(project.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    if !agent.status.isBusy, agent.hasActivityDate { AgentTimeLabel(date: agent.lastActivityAt) }
                }
                Text(agent.statusLine).font(.caption).foregroundStyle(statusColor).lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}
