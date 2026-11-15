import SwiftUI

struct ApprovalBrief: View {
    let approval: Approval
    var onOpenAgent: ((Agent) -> Void)?

    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !approval.summary.isEmpty {
                Text(approval.summary)
                    .font(Surface.code)
                    .lineLimit(6)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if !approval.isSummaryComplete {
                    Text("Not everything is shown here.").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let agent = store.agent(for: approval), let onOpenAgent {
                    Button("Show details") { onOpenAgent(agent) }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .accessibilityHint("Opens the main window with everything the agent wants to do")
                }
            }
        }
    }
}
