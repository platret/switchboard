import Foundation

extension AppStore {
    func receive(_ message: ServerMessage) {
        let before = agents
        let known = Set(approvals.map(\.id))
        apply(message)
        switch message {
        case .bootstrap:
            if let selectedAgentId { loadHistory(agentId: selectedAgentId) }
            resendPendingAnswers()
            notifications?.withdrawApprovals(except: Set(approvals.map(\.id)))
            for approval in approvals where !known.contains(approval.id) { announce(approval) }
            notifications?.setBadge(approvals.count)
        case .approvalRequested(let approval):
            announce(approval)
            notifications?.setBadge(approvals.count)
        case .approvalResolved(let resolution):
            notifications?.withdrawApproval(id: resolution.approvalId)
            notifications?.setBadge(approvals.count)
        case .agentUpserted(let agent):
            let wasBusy = before[agent.id]?.status.isBusy == true
            let finished = wasBusy && !agent.status.isBusy && agent.queue.isEmpty
            if finished, settings.notifiesWhenFinished { notifications?.postFinished(agent) }
        default:
            break
        }
    }

    private func announce(_ approval: Approval) {
        guard pendingAnswers[approval.id] == nil else { return }
        notifications?.postApproval(approval, agentName: agents[approval.agentId]?.name ?? "An agent")
    }
}
