import Foundation

extension AppStore {
    func apply(_ message: ServerMessage) {
        switch message {
        case .authOk, .ping, .unknown:
            break
        case .bootstrap(let bootstrap):
            apply(bootstrap)
        case .history(let agentId, let history):
            items[agentId] = history.items
            drafts[agentId] = history.drafts
            loadedHistories.insert(agentId)
        case .agentUpserted(let agent):
            agents[agent.id] = agent
        case .agentRemoved(let agentId):
            forget(agentId: agentId)
        case .chatDelta(let agentId, let itemId, let text):
            appendDelta(agentId: agentId, itemId: itemId, text: text)
        case .chatItem(let item):
            upsert(item)
        case .approvalRequested(let approval):
            approvals.removeAll { $0.id == approval.id }
            approvals.append(approval)
        case .approvalResolved(let resolution):
            approvals.removeAll { $0.id == resolution.approvalId }
            pendingAnswers[resolution.approvalId] = nil
        case .error(let message):
            notice = message
        }
    }

    private func apply(_ bootstrap: Bootstrap) {
        projects = bootstrap.projects
        roles = bootstrap.roles
        approvals = bootstrap.approvals
        hostInfo = bootstrap.host
        agents = Dictionary(bootstrap.agents.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        pendingAnswers = pendingAnswers.filter { answer in approvals.contains { $0.id == answer.key } }
        loadedHistories.removeAll()
        isReady = true
        if !projects.contains(where: { $0.id == selectedProjectId }) { selectedProjectId = projects.first?.id }
        if let selectedAgentId, agents[selectedAgentId] == nil { self.selectedAgentId = nil }
    }

    private func forget(agentId: String) {
        agents[agentId] = nil
        items[agentId] = nil
        drafts[agentId] = nil
        loadedHistories.remove(agentId)
        for approval in approvals where approval.agentId == agentId { pendingAnswers[approval.id] = nil }
        approvals.removeAll { $0.agentId == agentId }
        if selectedAgentId == agentId { selectedAgentId = nil }
    }

    private func appendDelta(agentId: String, itemId: String, text: String) {
        var list = drafts[agentId] ?? []
        if let index = list.firstIndex(where: { $0.id == itemId }) {
            list[index].text += text
        } else {
            list.append(ChatDraft(id: itemId, text: text))
        }
        drafts[agentId] = list
    }

    private func upsert(_ item: ChatItem) {
        var list = items[item.agentId] ?? []
        if let index = list.firstIndex(where: { $0.id == item.id }) {
            list[index] = item
        } else {
            list.append(item)
        }
        items[item.agentId] = list
        drafts[item.agentId]?.removeAll { $0.id == item.id }
    }
}
