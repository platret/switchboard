import Foundation
import Observation

@MainActor
@Observable
final class OnboardingModel {
    private(set) var step: OnboardingStep = .welcome
    private(set) var isForward = true
    var pairingToken: String?
    var isPresented = false

    let checks: SystemChecks
    let projects: ProjectsEditor
    let host: HostController

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored var onFinish: (() -> Void)?
    @ObservationIgnored var onHostRunning: (() -> Void)?
    @ObservationIgnored private var needsRestart = false

    init(host: HostController, settings: AppSettings, checks: SystemChecks, projects: ProjectsEditor) {
        self.host = host
        self.settings = settings
        self.checks = checks
        self.projects = projects
    }

    var pairingLink: PairingLink? {
        guard let address = checks.tailscaleAddress, let pairingToken else { return nil }
        return PairingLink(host: address, port: host.port, token: pairingToken)
    }

    func move(to target: OnboardingStep) {
        guard target != step else { return }
        isForward = target > step
        step = target
    }

    func advance() {
        guard let next = step.next else { return finish() }
        move(to: next)
        Task { await enter(next) }
    }

    func goBack() {
        guard let previous = step.previous else { return }
        move(to: previous)
    }

    func restart() {
        isForward = true
        step = .welcome
    }

    func saveProjectsAndContinue() async {
        let changed = await projects.save()
        guard projects.failure == nil else { return }
        if changed, host.isRunning, host.ownsProcess { needsRestart = true }
        advance()
    }

    func startHost() async {
        if needsRestart {
            needsRestart = false
            await host.restart()
        } else if !host.isRunning {
            await host.start()
        }
        if host.isRunning { onHostRunning?() }
    }

    func finish() {
        settings.hasCompletedOnboarding = true
        if settings.hostSource == nil { settings.hostSource = host.source?.kind.rawValue }
        onFinish?()
    }

    private func enter(_ step: OnboardingStep) async {
        switch step {
        case .checks:
            await checks.refresh()
        case .projects:
            await host.readConfiguration()
            await projects.load(ProjectsLocation(source: host.source))
        case .host:
            await startHost()
        case .phone:
            await loadPairingToken()
        case .welcome, .done:
            break
        }
    }

    private func loadPairingToken() async {
        let folder = host.source?.envFolder ?? ""
        pairingToken = await Task.detached { EnvFile.token(inFolder: folder) }.value
    }
}
