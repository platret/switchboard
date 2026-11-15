import Foundation

extension AppStore {
    @discardableResult
    func send(_ text: String, to agentId: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= ClientMessage.chatTextMaxLength else {
            notice = "That message is too long to send."
            return false
        }
        return deliver(.chatSend(agentId: agentId, text: trimmed))
    }

    func stop(agentId: String) {
        deliver(.agentStop(agentId: agentId))
    }

    func removeQueued(agentId: String, id: String) {
        deliver(.queueRemove(agentId: agentId, id: id))
    }

    func loadHistory(agentId: String) {
        client.send(.historyGet(agentId: agentId))
    }

    @discardableResult
    func createAgent(projectId: String, role: String, name: String) async throws -> Agent {
        let agent = try await client.createAgent(projectId: projectId, role: role, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        apply(.agentUpserted(agent))
        openAgent(agent)
        return agent
    }

    func renameAgent(id: String, name: String) async throws {
        let agent = try await client.renameAgent(id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        apply(.agentUpserted(agent))
    }

    func deleteAgent(id: String) async throws {
        try await client.deleteAgent(id: id)
        apply(.agentRemoved(agentId: id))
    }

    func selectProject(_ projectId: String?) {
        selectedProjectId = projectId
        settings.lastProjectId = projectId
        if let agent = selectedAgent, agent.projectId != projectId { selectedAgentId = nil }
    }

    func selectAgent(_ agentId: String?) {
        selectedAgentId = agentId
        guard let agentId, !isHistoryLoaded(agentId) else { return }
        loadHistory(agentId: agentId)
    }

    func openAgent(_ agent: Agent) {
        selectedProjectId = agent.projectId
        settings.lastProjectId = agent.projectId
        selectAgent(agent.id)
    }

    func openAgent(id: String) {
        guard let agent = agents[id] else { return }
        openAgent(agent)
    }

    func dismissNotice() {
        notice = nil
    }

    func sendFailed(_ message: ClientMessage) {
        if case .chatSend = message { notice = ClientError.notDelivered.errorDescription }
    }

    @discardableResult
    func deliver(_ message: ClientMessage) -> Bool {
        if isLinkStale {
            connect()
        } else if client.send(message) {
            return true
        }
        notice = ClientError.notConnected.errorDescription
        return false
    }
}
