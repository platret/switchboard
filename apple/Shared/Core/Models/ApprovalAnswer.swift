import Foundation

struct ApprovalAnswer: Hashable, Sendable {
    let decision: ApprovalDecision
    var scope: ApprovalScope = .once

    func message(for approvalId: String) -> ClientMessage {
        .approvalRespond(approvalId: approvalId, decision: decision, scope: scope)
    }
}
