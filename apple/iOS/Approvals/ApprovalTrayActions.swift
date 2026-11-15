import SwiftUI

struct ApprovalTrayActions: View {
    let approval: Approval

    @Environment(AppStore.self) private var store

    private var subject: String {
        "\(store.agent(for: approval)?.name ?? "the agent") to \(approval.action)"
    }

    var body: some View {
        if store.isAnswered(approval) {
            HStack(spacing: 8) {
                ProgressView()
                Text("Sending your answer").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: 8) {
                if approval.supportsTurnScope {
                    button("Allow edits this turn", kind: .secondary, hint: "Allow \(subject) and every other edit in the project for the rest of this turn") {
                        store.respond(to: approval, decision: .allow, scope: .turn)
                    }
                }
                HStack(spacing: 8) {
                    button("Deny", kind: .destructive, hint: "Deny \(subject)") {
                        store.respond(to: approval, decision: .deny)
                    }
                    button("Allow", kind: .primary, hint: "Allow \(subject)") {
                        store.respond(to: approval, decision: .allow)
                    }
                }
            }
            .disabled(store.isApprovalInputHeld)
            .sensoryFeedback(.selection, trigger: store.isAnswered(approval))
        }
    }

    private func button(_ title: String, kind: ActionButtonKind, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(ActionButtonStyle(kind: kind))
        .accessibilityLabel(hint)
    }
}
