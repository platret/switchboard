import SwiftUI

struct ApprovalList: View {
    var agentId: String?
    var style: ApprovalCardStyle = .full
    var onOpenAgent: ((Agent) -> Void)?

    @Environment(AppStore.self) private var store

    private var approvals: [Approval] {
        agentId.map { store.approvals(for: $0) } ?? store.approvals
    }

    var body: some View {
        VStack(spacing: style == .full ? 12 : 8) {
            ForEach(approvals) { approval in
                ApprovalCard(approval: approval, style: style, onOpenAgent: onOpenAgent)
            }
        }
    }
}
