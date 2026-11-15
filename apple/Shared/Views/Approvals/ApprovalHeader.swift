import SwiftUI

struct ApprovalHeader: View {
    let approval: Approval
    var onOpenAgent: ((Agent) -> Void)?

    @Environment(AppStore.self) private var store

    private var agent: Agent? {
        store.agent(for: approval)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let agent, let onOpenAgent {
                Button {
                    onOpenAgent(agent)
                } label: {
                    title
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the chat")
            } else {
                title
            }
            Spacer(minLength: 8)
            ApprovalCountdown(approval: approval)
        }
    }

    private var title: some View {
        HStack(alignment: .top, spacing: 10) {
            AgentAvatar(name: agent?.name ?? "Agent", id: approval.agentId, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(agent?.name ?? "An agent") wants to \(approval.action)")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let project = agent.flatMap({ store.project(of: $0) }) {
                    Text(project.name).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
