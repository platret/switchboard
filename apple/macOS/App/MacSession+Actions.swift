import AppKit

extension MacSession {
    func open(_ agent: Agent) {
        store.openAgent(agent)
        showMainWindow()
    }

    func open(agentId: String) {
        store.openAgent(id: agentId)
        showMainWindow()
    }

    func openShortcutAgent(at index: Int) {
        let agents = shortcutAgents
        guard agents.indices.contains(index) else { return }
        open(agents[index])
    }

    func showOverview() {
        store.selectAgent(nil)
        showMainWindow()
    }

    func newAgent() {
        guard store.isReady, store.selectedProject != nil else { return }
        showMainWindow()
        showsCreate = true
    }

    func quickSwitch() {
        showMainWindow()
        showsSwitcher = true
    }

    func pairPhone() {
        showMainWindow()
        showsPairing = true
    }

    func stopSelected() {
        guard let agent = store.selectedAgent, agent.status.isBusy else { return }
        store.stop(agentId: agent.id)
    }

    func renameSelected() {
        renaming = store.selectedAgent
    }

    func deleteSelected() {
        deleting = store.selectedAgent
    }

    func openWebApp() {
        guard let url = host.webURL else { return }
        NSWorkspace.shared.open(url)
    }
}
