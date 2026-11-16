import AppKit
import SwiftUI
import XCTest

@MainActor
final class OnboardingSnapshotTests: XCTestCase {
    private static let token = "sample-token-used-only-for-snapshot-renders"

    private var rendered: [URL] = []

    override func setUp() async throws {
        _ = NSApplication.shared
        let testBundle = Bundle(for: OnboardingSnapshotTests.self)
        if let icon = testBundle.image(forResource: "AppIcon") { NSApp.applicationIconImage = icon }
        SnapshotBundle.bundle = testBundle
        SnapshotBundle.swapMainBundle()
    }

    override func tearDown() async throws {
        SnapshotBundle.swapMainBundle()
        SnapshotBundle.bundle = nil
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("switchboard-snapshots-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func snapshot(_ configure: (inout SystemSnapshot) -> Void) -> SystemSnapshot {
        var snapshot = SystemSnapshot()
        snapshot.runtime = .bundled
        snapshot.claudePath = "/Applications/Switchboard.app/Contents/Resources/Host/claude"
        configure(&snapshot)
        return snapshot
    }

    private var missing: SystemSnapshot {
        snapshot { snapshot in
            snapshot.claudeApp = AppPresence(isInstalled: true, isRunning: true)
            snapshot.tailscale = AppPresence(isInstalled: true, isRunning: false)
            snapshot.notifications = .notDetermined
        }
    }

    private var ready: SystemSnapshot {
        snapshot { snapshot in
            snapshot.isClaudeSignedIn = true
            snapshot.isHostRunning = true
            snapshot.claudeApp = AppPresence(isInstalled: true, isRunning: true)
            snapshot.tailscale = AppPresence(isInstalled: true, isRunning: true)
            snapshot.tailscaleAddress = "100.101.102.103"
            snapshot.notifications = .allowed
        }
    }

    private var noTailscale: SystemSnapshot {
        snapshot { snapshot in
            snapshot.isClaudeSignedIn = true
            snapshot.notifications = .allowed
        }
    }

    private func model(step: OnboardingStep, checks: SystemSnapshot?, projects: ProjectsEditor? = nil, host: HostController? = nil) throws -> OnboardingModel {
        let settings = Fixtures.store().settings
        let controller = try host ?? HostController(settings: settings, bundled: nil, home: temporaryFolder())
        let model = OnboardingModel(host: controller, settings: settings, checks: SystemChecks(host: nil, probe: nil, snapshot: checks), projects: projects ?? ProjectsEditor())
        model.pairingToken = OnboardingSnapshotTests.token
        model.move(to: step)
        return model
    }

    private func render(_ name: String, _ model: OnboardingModel) throws {
        for dark in [false, true] {
            let view = OnboardingView(model: model).environment(\.revealsInstantly, true)
            rendered.append(try SnapshotRenderer.render(view, size: OnboardingView.size, dark: dark, name: name))
        }
    }

    private func editableProjects(_ projects: [Project]) throws -> ProjectsEditor {
        let location = ProjectsLocation(file: try temporaryFolder().appendingPathComponent("projects.json"), roleFiles: [], isEditable: true)
        return ProjectsEditor(projects: projects, roles: RoleCatalog.fallback, location: location)
    }

    private static let sampleProjects = [
        Project(id: "webapp", name: "Web app", path: "~/Developer/webapp", agents: ["dev", "tester", "reviewer"]),
        Project(id: "notes", name: "Notes", path: "~/Documents/Projects/notes", agents: ["ideation", "dev"]),
        Project(id: "site", name: "Portfolio site", path: "~/Developer/portfolio-site", agents: ["dev", "deploy-check"]),
    ]

    func testRenderEveryStep() async throws {
        try render("1-welcome", model(step: .welcome, checks: nil))
        try render("2-checks-checking", model(step: .checks, checks: nil))
        try render("2-checks-missing", model(step: .checks, checks: missing))
        try render("2-checks-ready", model(step: .checks, checks: ready))
        try render("3-projects-empty", model(step: .projects, checks: ready, projects: editableProjects([])))
        try render("3-projects-list", model(step: .projects, checks: ready, projects: editableProjects(OnboardingSnapshotTests.sampleProjects)))
        let repo = ProjectsEditor(projects: Array(OnboardingSnapshotTests.sampleProjects.prefix(2)), roles: RoleCatalog.fallback, location: ProjectsLocation(file: URL(fileURLWithPath: "/Users/me/Developer/switchboard/projects.json"), roleFiles: [], isEditable: false))
        try render("3-projects-repo", model(step: .projects, checks: ready, projects: repo))
        try render("5-phone-paired", model(step: .phone, checks: ready))
        try render("5-phone-no-tailscale", model(step: .phone, checks: noTailscale))
        try render("6-done", model(step: .done, checks: ready))
        XCTAssertEqual(rendered.count, 20)
    }

    func testRenderHostStates() async throws {
        let failing = try BundledHostTests.install(port: 4394, script: """
        print "Switchboard host 2.1.0"
        print "Reading /Users/me/Library/Application Support/Switchboard/projects.json"
        print "Error: projects.json: project \\"webapp\\" lists unknown role \\"designer\\"" >&2
        print "    at loadProjects (config.ts:118:13)" >&2
        exit 1
        """)
        let failed = BundledHostTests.controller(for: failing)
        await failed.start()
        try await Task.sleep(for: .milliseconds(300))
        try render("4-host-failed", model(step: .host, checks: ready, host: failed))

        let slow = try BundledHostTests.install(port: 4395, script: "sleep 30")
        let starting = BundledHostTests.controller(for: slow)
        let launch = Task { await starting.start() }
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(starting.state, .starting)
        try render("4-host-starting", model(step: .host, checks: ready, host: starting))
        starting.releaseProcess()
        await launch.value

        let port = 4392
        let serving = try BundledHostTests.install(port: port, script: "exec python3 -m http.server \(port) --bind 127.0.0.1")
        let running = BundledHostTests.controller(for: serving)
        await running.start()
        XCTAssertEqual(running.state, .running)
        try render("4-host-running", model(step: .host, checks: ready, host: running))
        await running.stop()
        XCTAssertEqual(rendered.count, 6)
    }
}
