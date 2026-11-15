import AppKit
import Observation

@MainActor
@Observable
final class MacSession {
    static let shared = MacSession()
    static let mainWindowID = "main"

    let store: AppStore
    let host: HostController

    var showsCreate = false
    var showsSwitcher = false
    var showsPairing = false
    var renaming: Agent?
    var deleting: Agent?

    @ObservationIgnored var openMainWindow: (() -> Void)?
    @ObservationIgnored private var monitor: Task<Void, Never>?

    init() {
        let store = AppStore.live()
        self.store = store
        host = HostController(settings: store.settings)
    }

    var shortcutAgents: [Agent] {
        store.selectedProject.map { store.agents(in: $0.id) } ?? []
    }

    func launch() {
        guard monitor == nil else { return }
        store.notificationService?.onOpenAgent = { [weak self] agentId in self?.open(agentId: agentId) }
        Task { await store.notificationService?.requestAuthorization() }
        monitor = Task {
            await locateRepo()
            store.start()
            await watchHost()
        }
    }

    func startHost() async {
        await host.start()
        reconnectIfNeeded()
    }

    func showMainWindow() {
        openMainWindow?()
        for window in NSApp.windows where window.identifier?.rawValue.hasPrefix(MacSession.mainWindowID) == true {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate()
    }

    private func locateRepo() async {
        guard store.settings.repoFolder.isEmpty else { return }
        let found = await store.readingFolders { RepoLocator.find() }
        if let found, store.settings.repoFolder.isEmpty { store.settings.repoFolder = found }
    }

    private func watchHost() async {
        await host.startIfNeeded()
        var wasRunning = false
        while !Task.isCancelled {
            if host.isRunning, !wasRunning { reconnectIfNeeded() }
            wasRunning = host.isRunning
            try? await Task.sleep(for: .seconds(5))
            await host.refresh()
        }
    }

    private func reconnectIfNeeded() {
        guard host.isRunning, store.connection == .notConfigured || store.connection == .reconnecting else { return }
        store.connect()
    }
}
