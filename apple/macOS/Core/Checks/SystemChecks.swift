import AppKit
import Observation
import UserNotifications

@MainActor
@Observable
final class SystemChecks {
    static let interval: Duration = .seconds(2)

    var snapshot: SystemSnapshot?

    @ObservationIgnored private let probe: SystemProbe?
    @ObservationIgnored private let host: HostController?
    @ObservationIgnored private var toolchain: RepoToolchain?
    @ObservationIgnored private var isRefreshing = false

    init(host: HostController?, probe: SystemProbe?, snapshot: SystemSnapshot? = nil) {
        self.host = host
        self.probe = probe
        self.snapshot = snapshot
    }

    var checks: [SetupCheck] {
        SetupChecklist.checks(for: snapshot)
    }

    var requiredPassed: Bool {
        SetupChecklist.requiredPassed(checks)
    }

    var tailscaleAddress: String? {
        snapshot?.tailscaleAddress
    }

    func refresh() async {
        guard let probe, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await host?.refresh()
        let kind = host?.source?.kind
        let known = toolchain
        var next = await Task.detached { probe.gather(source: kind, toolchain: known) }.value
        if case .repo(let found) = next.runtime, found.isReady { toolchain = found }
        next.notifications = await NotificationAccess.current()
        next.isHostRunning = host?.isRunning ?? false
        next.port = host?.port ?? HostEndpoint.defaultPort
        if next != snapshot { snapshot = next }
    }

    func watch() async {
        guard probe != nil else { return }
        let workspace = NSWorkspace.shared.notificationCenter
        await withTaskGroup(of: Void.self) { group in
            for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
                group.addTask { @MainActor [weak self] in
                    for await _ in workspace.notifications(named: name) { await self?.refresh() }
                }
            }
            group.addTask { @MainActor [weak self] in
                for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) { await self?.refresh() }
            }
            group.addTask { @MainActor [weak self] in
                while !Task.isCancelled {
                    await self?.refresh()
                    try? await Task.sleep(for: SystemChecks.interval)
                }
            }
        }
    }

    func perform(_ action: CheckAction) async {
        let workspace = NSWorkspace.shared
        switch action {
        case .signIn:
            openSignIn()
        case .openClaude:
            open(identifiers: KnownApp.claudeIdentifiers, paths: [])
        case .openTailscale:
            open(identifiers: KnownApp.tailscaleIdentifiers, paths: KnownApp.tailscalePaths)
        case .allowNotifications:
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        case .getClaudeCode, .getClaude, .getTailscale, .openNotificationSettings, .getNode, .getPnpm:
            if let link = action.link { workspace.open(link) }
        }
        await refresh()
    }

    private func openSignIn() {
        guard let claude = snapshot?.claudePath, let script = try? ClaudeCLI.writeSignInScript(claude: claude) else { return }
        let workspace = NSWorkspace.shared
        guard let terminal = workspace.urlForApplication(withBundleIdentifier: KnownApp.terminalIdentifier) else {
            workspace.open(script)
            return
        }
        workspace.open([script], withApplicationAt: terminal, configuration: NSWorkspace.OpenConfiguration())
    }

    private func open(identifiers: [String], paths: [String]) {
        let presence = AppPresence.find(bundleIdentifiers: identifiers, paths: paths)
        guard let location = presence.location else { return }
        NSWorkspace.shared.openApplication(at: location, configuration: NSWorkspace.OpenConfiguration())
    }
}
