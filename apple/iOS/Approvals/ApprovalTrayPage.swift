import SwiftUI

struct ApprovalTrayPage: View {
    let approval: Approval
    let onDetails: () -> Void

    @Environment(AppStore.self) private var store

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ApprovalHeader(approval: approval) { agent in store.openAgent(agent) }
            Button(action: onDetails) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(approval.summary.isEmpty ? "Show what it wants to do" : approval.summary)
                        .font(Surface.code)
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.up").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Surface.sunken, in: RoundedRectangle(cornerRadius: Surface.corner, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Details: \(approval.summary)")
            .accessibilityHint("Shows everything the agent wants to do")
            ApprovalTrayActions(approval: approval)
        }
        .padding(12)
        .background(Palette.amber.opacity(0.12), in: shape)
        .overlay(shape.strokeBorder(Palette.amber.opacity(0.55)))
        .accessibilityElement(children: .contain)
    }
}
