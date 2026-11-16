import AppKit
import Observation

@MainActor
@Observable
final class MacSession {
    static let shared = MacSession()
    static let mainWindowID = "main"
    static let onboardingWindowID = "onboarding"

    let store: AppStore
    let host: HostController
    let projects: ProjectsEditor
    let onboarding: OnboardingModel

    var showsCreate = false
    var showsSwitcher = false
    var showsPairing = false
    var renaming: Agent?
    var deleting: Agent?

    @ObservationIgnored var openMainWindow: (() -> Void)?
    @ObservationIgnored var openOnboarding: (() -> Void)?
    @ObservationIgnored private var monitor: Task<Void, Never>?
    @ObservationIgnored private var didPresentLaunchOnboarding = false
    @ObservationIgnored private var didHideLaunchWindow = false
    @ObservationIgnored private let launchedAt = Date()

    init() {
        let store = AppStore.live()
        let host = HostController(settings: store.settings)
        let projects = ProjectsEditor()
        let checks = SystemChecks(host: host, probe: SystemProbe(bundled: host.bundled))
        self.store = store
        self.host = host
        self.projects = projects
        onboarding = OnboardingModel(host: host, settings: store.settings, checks: checks, projects: projects)
        onboarding.onHostRunning = { [weak self] in self?.reconnectIfNeeded() }
        store.localEnvFolder = { [weak host, settings = store.settings] in host?.source?.envFolder ?? settings.repoFolder }
    }

    var shortcutAgents: [Agent] {
        store.selectedProject.map { store.agents(in: $0.id) } ?? []
    }

    var needsOnboarding: Bool {
        !store.settings.hasCompletedOnboarding
    }

    func launch() {
        guard monitor == nil else { return }
        store.notificationService?.onOpenAgent = { [weak self] agentId in self?.open(agentId: agentId) }
        if !needsOnboarding { Task { await store.notificationService?.requestAuthorization() } }
        monitor = Task {
            await locateRepo()
            await host.readConfiguration()
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

    func showOnboarding() {
        if !onboarding.isPresented { onboarding.restart() }
        openOnboarding?()
        for window in NSApp.windows where window.identifier?.rawValue.hasPrefix(MacSession.onboardingWindowID) == true {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate()
    }

    func presentOnboardingAtLaunch() {
        guard needsOnboarding, !didPresentLaunchOnboarding else { return }
        didPresentLaunchOnboarding = true
        showOnboarding()
    }

    func hidesMainWindowAtLaunch() -> Bool {
        guard needsOnboarding, !didHideLaunchWindow, Date().timeIntervalSince(launchedAt) < 10 else { return false }
        didHideLaunchWindow = true
        presentOnboardingAtLaunch()
        return true
    }

    func reconnectIfNeeded() {
        guard host.isRunning else { return }
        if host.source?.kind == .bundled {
            Task { await adoptHostToken() }
            return
        }
        guard store.connection == .notConfigured || store.connection == .reconnecting else { return }
        store.connect()
    }

    private func adoptHostToken() async {
        guard let folder = host.source?.envFolder else { return }
        let token = await Task.detached { EnvFile.token(inFolder: folder) }.value
        guard let token else { return }
        let address = "http://127.0.0.1:\(host.port)"
        let isCurrent = store.tokens.read() == token && store.settings.endpoint == HostEndpoint(string: address)
        if isCurrent, store.connection != .notConfigured, store.connection != .tokenRejected {
            if store.connection == .reconnecting { store.connect() }
            return
        }
        try? store.saveConnection(host: address, token: token)
    }

    private func locateRepo() async {
        guard store.settings.repoFolder.isEmpty, store.settings.hostSource != HostSourceKind.bundled.rawValue else { return }
        let found = await store.readingFolders { RepoLocator.find() }
        if let found, store.settings.repoFolder.isEmpty { store.settings.repoFolder = found }
    }

    private func watchHost() async {
        if needsOnboarding {
            await host.refresh()
        } else {
            await host.startIfNeeded()
        }
        var wasRunning = false
        while !Task.isCancelled {
            if host.isRunning, !wasRunning { reconnectIfNeeded() }
            wasRunning = host.isRunning
            try? await Task.sleep(for: .seconds(5))
            await host.refresh()
        }
    }
}
