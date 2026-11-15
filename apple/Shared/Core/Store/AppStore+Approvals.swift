import Foundation

extension AppStore {
    static let answerPatience: TimeInterval = 5
    static let approvalHoldTime: TimeInterval = 0.6

    func respond(to approval: Approval, decision: ApprovalDecision, scope: ApprovalScope = .once) {
        guard !isApprovalInputHeld else { return }
        respond(approvalId: approval.id, decision: decision, scope: approval.supportsTurnScope ? scope : .once)
    }

    func respond(approvalId: String, decision: ApprovalDecision, scope: ApprovalScope = .once) {
        let answer = ApprovalAnswer(decision: decision, scope: scope)
        guard deliver(answer.message(for: approvalId)) else { return }
        pendingAnswers[approvalId] = answer
        confirmDelivery(of: approvalId)
    }

    func answerFromNotification(approvalId: String, decision: ApprovalDecision) {
        guard connection == .connected, !isLinkStale else {
            pendingAnswers[approvalId] = ApprovalAnswer(decision: decision)
            if connection != .connecting { connect() }
            return
        }
        if approvals.contains(where: { $0.id == approvalId }) { respond(approvalId: approvalId, decision: decision) }
    }

    func resendPendingAnswers() {
        for (approvalId, answer) in pendingAnswers {
            client.send(answer.message(for: approvalId))
        }
    }

    func holdApprovalInput() {
        approvalHold?.cancel()
        isApprovalInputHeld = !approvals.isEmpty
        guard isApprovalInputHeld else { return }
        approvalHold = Task { [weak self] in
            try? await Task.sleep(for: .seconds(AppStore.approvalHoldTime))
            if !Task.isCancelled { self?.isApprovalInputHeld = false }
        }
    }

    private func confirmDelivery(of approvalId: String) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(AppStore.answerPatience))
            guard let self, self.pendingAnswers[approvalId] != nil, self.connection == .connected else { return }
            self.connect()
        }
    }
}
