import SwiftUI

struct ApprovalCard: View {
    let approval: Approval
    var style: ApprovalCardStyle = .full
    var onOpenAgent: ((Agent) -> Void)?

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ApprovalHeader(approval: approval, onOpenAgent: onOpenAgent)
            switch style {
            case .full:
                ApprovalDetails(detail: approval.detail)
            case .compact:
                ApprovalBrief(approval: approval, onOpenAgent: onOpenAgent)
            }
            ApprovalActions(approval: approval)
        }
        .padding(style == .full ? 14 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.amber.opacity(0.10), in: shape)
        .overlay(shape.strokeBorder(Palette.amber.opacity(0.55)))
        .accessibilityElement(children: .contain)
    }
}
