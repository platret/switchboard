import Foundation

extension AppStore {
    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectId }
    }

    var selectedAgent: Agent? {
        selectedAgentId.flatMap { agents[$0] }
    }

    var agentsByUrgency: [Agent] {
        agents.values.sorted(by: Agent.byUrgency)
    }

    var waitingCount: Int {
        count(.waiting)
    }

    var workingCount: Int {
        count(.working)
    }

    var errorCount: Int {
        count(.error)
    }

    var summary: String {
        var parts: [String] = []
        if waitingCount > 0 { parts.append("\(waitingCount) need approval") }
        if errorCount > 0 { parts.append("\(errorCount) with errors") }
        if workingCount > 0 { parts.append("\(workingCount) working") }
        parts.append("\(count(.idle)) idle")
        return parts.joined(separator: ", ")
    }

    func count(_ status: AgentStatus) -> Int {
        agents.values.filter { $0.status == status }.count
    }

    func agents(in projectId: String) -> [Agent] {
        agents.values.filter { $0.projectId == projectId }.sorted(by: Agent.byCreation)
    }

    func project(id: String) -> Project? {
        projects.first { $0.id == id }
    }

    func project(of agent: Agent) -> Project? {
        project(id: agent.projectId)
    }

    func role(id: String) -> Role? {
        roles.first { $0.id == id }
    }

    func role(of agent: Agent) -> Role? {
        role(id: agent.role)
    }

    func roles(for project: Project) -> [Role] {
        project.agents.compactMap { role(id: $0) }
    }

    func agent(for approval: Approval) -> Agent? {
        agents[approval.agentId]
    }

    func approvals(for agentId: String) -> [Approval] {
        approvals.filter { $0.agentId == agentId }
    }

    func items(for agentId: String) -> [ChatItem] {
        items[agentId] ?? []
    }

    func drafts(for agentId: String) -> [ChatDraft] {
        drafts[agentId] ?? []
    }

    func isHistoryLoaded(_ agentId: String) -> Bool {
        loadedHistories.contains(agentId)
    }

    func isAnswered(_ approval: Approval) -> Bool {
        pendingAnswers[approval.id] != nil
    }
}
