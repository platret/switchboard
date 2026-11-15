import SwiftUI

struct ApprovalActions: View {
    let approval: Approval

    @Environment(AppStore.self) private var store

    private var subject: String {
        "\(store.agent(for: approval)?.name ?? "the agent") to \(approval.action)"
    }

    var body: some View {
        if store.isAnswered(approval) {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Sending your answer").font(.callout).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    deny(isWide: false)
                    Spacer(minLength: 8)
                    allowTurn(isWide: false)
                    allow(isWide: false)
                }
                VStack(spacing: 8) {
                    allow(isWide: true)
                    allowTurn(isWide: true)
                    deny(isWide: true)
                }
            }
            .disabled(store.isApprovalInputHeld)
        }
    }

    private func deny(isWide: Bool) -> some View {
        Button(role: .destructive) {
            store.respond(to: approval, decision: .deny)
        } label: {
            Text("Deny").frame(maxWidth: isWide ? .infinity : nil)
        }
        .buttonStyle(ActionButtonStyle(kind: .destructive))
        .accessibilityLabel("Deny \(subject)")
    }

    private func allow(isWide: Bool) -> some View {
        Button {
            store.respond(to: approval, decision: .allow)
        } label: {
            Text("Allow").frame(maxWidth: isWide ? .infinity : nil)
        }
        .buttonStyle(ActionButtonStyle(kind: .primary))
        .accessibilityLabel("Allow \(subject)")
    }

    @ViewBuilder private func allowTurn(isWide: Bool) -> some View {
        if approval.supportsTurnScope {
            Button {
                store.respond(to: approval, decision: .allow, scope: .turn)
            } label: {
                Text("Allow edits this turn").frame(maxWidth: isWide ? .infinity : nil)
            }
            .buttonStyle(ActionButtonStyle(kind: .secondary))
            .accessibilityLabel("Allow \(subject) and every other edit in the project for the rest of this turn")
        }
    }
}
