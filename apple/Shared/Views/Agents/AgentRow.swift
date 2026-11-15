import SwiftUI

struct AgentRow: View {
    let agent: Agent
    var showsProject = false

    @Environment(AppStore.self) private var store

    private var subtitle: String {
        let role = store.role(of: agent)?.name ?? agent.role
        guard showsProject, let project = store.project(of: agent) else { return role }
        return "\(role) in \(project.name)"
    }

    private var statusColor: Color {
        agent.status == .idle ? .secondary : Palette.lamp(agent.status)
    }

    var body: some View {
        HStack(spacing: 10) {
            StatusLamp(status: agent.status)
            AgentAvatar(agent: agent)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(agent.name).font(.body.weight(.medium)).lineLimit(1)
                    Spacer(minLength: 4)
                    if !agent.status.isBusy, agent.hasActivityDate { AgentTimeLabel(date: agent.lastActivityAt) }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 6) {
                    Text(agent.statusLine).foregroundStyle(statusColor).lineLimit(1)
                    if !agent.queue.isEmpty { Text("\(agent.queue.count) queued").foregroundStyle(.secondary).fixedSize() }
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(agent.status == .waiting ? Palette.amber.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: Surface.corner, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    private var spokenLabel: String {
        var parts = [agent.name, subtitle, agent.status.label]
        if agent.status != .waiting { parts.append(agent.statusLine) }
        if !agent.queue.isEmpty { parts.append("\(agent.queue.count) queued") }
        if !agent.status.isBusy, agent.hasActivityDate { parts.append(RelativeTime.spoken(from: agent.lastActivityAt)) }
        return parts.joined(separator: ", ")
    }
}
