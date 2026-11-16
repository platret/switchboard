import XCTest

final class OnboardingLogicTests: XCTestCase {
    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("switchboard-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
        return folder
    }

    private func bundledHost() throws -> BundledHost {
        let root = try temporaryFolder().appendingPathComponent("Host")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try "#!/bin/zsh\n".write(to: root.appendingPathComponent("start"), atomically: true, encoding: .utf8)
        return try XCTUnwrap(BundledHost(root: root))
    }

    private func permissions(_ url: URL) throws -> Int {
        try XCTUnwrap(FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int)
    }

    func testBundledHostNeedsItsStartScript() throws {
        XCTAssertNil(BundledHost(root: try temporaryFolder()))
        let host = try bundledHost()
        XCTAssertEqual(host.start.lastPathComponent, "start")
        XCTAssertEqual(host.roles.pathComponents.suffix(2), ["app", "roles.json"])
        XCTAssertNil(BundledHost.find(in: Bundle(for: OnboardingLogicTests.self)))
    }

    func testHostSourceResolution() throws {
        let bundled = try bundledHost()
        let home = URL(fileURLWithPath: "/tmp/switchboard-home")
        let clone = "/Users/me/code/switchboard"
        let valid: (String) -> Bool = { _ in true }
        let invalid: (String) -> Bool = { _ in false }

        XCTAssertEqual(HostSource.resolve(choice: nil, repoFolder: clone, bundled: bundled, home: home, isRepo: valid), .repo(folder: clone))
        XCTAssertEqual(HostSource.resolve(choice: nil, repoFolder: clone, bundled: bundled, home: home, isRepo: invalid), .bundled(bundled, home: home))
        XCTAssertEqual(HostSource.resolve(choice: nil, repoFolder: "", bundled: bundled, home: home, isRepo: valid), .bundled(bundled, home: home))
        XCTAssertEqual(HostSource.resolve(choice: nil, repoFolder: clone, bundled: nil, home: home, isRepo: invalid), .repo(folder: clone))
        XCTAssertNil(HostSource.resolve(choice: nil, repoFolder: "  ", bundled: nil, home: home, isRepo: valid))
        XCTAssertEqual(HostSource.resolve(choice: .bundled, repoFolder: clone, bundled: bundled, home: home, isRepo: valid), .bundled(bundled, home: home))
        XCTAssertEqual(HostSource.resolve(choice: .bundled, repoFolder: clone, bundled: nil, home: home, isRepo: valid), .repo(folder: clone))
        XCTAssertEqual(HostSource.resolve(choice: .repo, repoFolder: clone, bundled: bundled, home: home, isRepo: invalid), .repo(folder: clone))
        XCTAssertEqual(HostSource.resolve(choice: .repo, repoFolder: "", bundled: bundled, home: home, isRepo: valid), .bundled(bundled, home: home))
    }

    func testHostSourceLaunches() throws {
        let bundled = try bundledHost()
        let home = URL(fileURLWithPath: "/tmp/switchboard-home")
        let launch = HostSource.bundled(bundled, home: home).launch
        XCTAssertEqual(launch.executable.path, "/bin/zsh")
        XCTAssertEqual(launch.arguments, [bundled.start.path])
        XCTAssertEqual(launch.folder, home.path)
        XCTAssertEqual(launch.environment, ["SWITCHBOARD_HOME": home.path])
        XCTAssertEqual(HostSource.bundled(bundled, home: home).envFolder, home.path)
        XCTAssertFalse(HostSource.bundled(bundled, home: home).startingDetail.contains("pnpm"))

        let repo = HostSource.repo(folder: "/Users/me/code/switchboard")
        XCTAssertEqual(repo.launch.arguments, ["-c", "pnpm start"])
        XCTAssertEqual(repo.launch.folder, "/Users/me/code/switchboard")
        XCTAssertTrue(repo.launch.environment.isEmpty)
        XCTAssertTrue(repo.launch.note.hasPrefix("Starting the host"))
    }

    @MainActor
    func testControllerWithoutAnySourceExplainsWhatToDo() async {
        let controller = HostController(settings: Fixtures.store().settings, bundled: nil, home: URL(fileURLWithPath: "/tmp/unused"))
        XCTAssertNil(controller.source)
        await controller.readConfiguration()
        XCTAssertNil(controller.source)
    }

    func testClaudeSignInReadsOnlyTheAccountKey() {
        let signedIn = Data(#"{"numStartups":3,"oauthAccount":{"emailAddress":"someone@example.com"}}"#.utf8)
        let signedOut = Data(#"{"numStartups":3,"oauthAccount":null}"#.utf8)
        let never = Data(#"{"numStartups":1}"#.utf8)
        XCTAssertTrue(ClaudeAccount.isSignedIn(config: signedIn))
        XCTAssertFalse(ClaudeAccount.isSignedIn(config: signedOut))
        XCTAssertFalse(ClaudeAccount.isSignedIn(config: never))
        XCTAssertFalse(ClaudeAccount.isSignedIn(config: Data("not json".utf8)))
        XCTAssertFalse(ClaudeAccount.isSignedIn(config: nil))
    }

    func testClaudeSignInIgnoresAnAPIKeyInTheEnvironment() throws {
        let home = try temporaryFolder()
        try #"{"numStartups":1}"#.write(to: home.appendingPathComponent(".claude.json"), atomically: true, encoding: .utf8)
        setenv("ANTHROPIC_API_KEY", "sk-test", 1)
        defer { unsetenv("ANTHROPIC_API_KEY") }
        XCTAssertFalse(ClaudeAccount.isSignedIn(home: home))
        XCTAssertFalse(SystemProbe(home: home).gather(source: nil, toolchain: nil).isClaudeSignedIn)
    }

    func testClaudeSignInReadsTheHomeFolder() throws {
        let home = try temporaryFolder()
        XCTAssertFalse(ClaudeAccount.isSignedIn(home: home))
        try #"{"oauthAccount":{"accountUuid":"x"}}"#.write(to: home.appendingPathComponent(".claude.json"), atomically: true, encoding: .utf8)
        XCTAssertTrue(ClaudeAccount.isSignedIn(home: home))
    }

    func testClaudeCLIPrefersTheUserInstallThenTheBundledOne() throws {
        let home = URL(fileURLWithPath: "/Users/me")
        let bundled = try bundledHost()
        XCTAssertEqual(ClaudeCLI.locate(home: home, bundled: bundled) { $0 == "/opt/homebrew/bin/claude" || $0 == bundled.claude.path }, "/opt/homebrew/bin/claude")
        XCTAssertEqual(ClaudeCLI.locate(home: home, bundled: bundled) { $0 == "/Users/me/.local/bin/claude" || $0 == "/usr/local/bin/claude" }, "/Users/me/.local/bin/claude")
        XCTAssertEqual(ClaudeCLI.locate(home: home, bundled: bundled) { $0 == bundled.claude.path }, bundled.claude.path)
        XCTAssertNil(ClaudeCLI.locate(home: home, bundled: nil) { _ in false })
    }

    func testSignInScriptRunsTheClaudeBinary() throws {
        let folder = try temporaryFolder()
        let script = try ClaudeCLI.writeSignInScript(claude: "/Users/me/it's here/claude", folder: folder)
        let text = try String(contentsOf: script, encoding: .utf8)
        XCTAssertTrue(text.hasPrefix("#!/bin/zsh\n"))
        XCTAssertTrue(text.contains("exec '/Users/me/it'\\''s here/claude'"))
        XCTAssertTrue(text.contains("/login"))
        XCTAssertEqual(try permissions(script), 0o755)
        XCTAssertEqual(script.pathExtension, "command")
    }

    func testToolVersionsCompare() {
        XCTAssertEqual(ToolVersion("v22.12.0"), ToolVersion(major: 22, minor: 12, patch: 0))
        XCTAssertEqual(ToolVersion("v25.1.0\n"), ToolVersion(major: 25, minor: 1, patch: 0))
        XCTAssertEqual(ToolVersion("24"), ToolVersion(major: 24, minor: 0, patch: 0))
        XCTAssertEqual(ToolVersion("v23.0.0-nightly2025"), ToolVersion(major: 23, minor: 0, patch: 0))
        XCTAssertNil(ToolVersion("node"))
        XCTAssertNil(ToolVersion(""))
        XCTAssertTrue(ToolVersion(major: 22, minor: 11, patch: 9) < .nodeMinimum)
        XCTAssertTrue(ToolVersion(major: 22, minor: 12, patch: 0) >= .nodeMinimum)
        XCTAssertTrue(ToolVersion(major: 24, minor: 0, patch: 0) > .nodeMinimum)
        XCTAssertFalse(RepoToolchain(node: ToolVersion("v20.1.0"), hasNode: true, hasPnpm: true).isReady)
        XCTAssertFalse(RepoToolchain(node: ToolVersion("v24.1.0"), hasNode: true, hasPnpm: false).isReady)
        XCTAssertTrue(RepoToolchain(node: ToolVersion("v24.1.0"), hasNode: true, hasPnpm: true).isReady)
    }

    func testRepoToolchainSearchesOnlyThePath() throws {
        let folder = try temporaryFolder()
        let node = folder.appendingPathComponent("node")
        try "#!/bin/sh\necho v22.12.1\n".write(to: node, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: node.path)
        let found = RepoToolchain.find(searchPath: folder.path)
        XCTAssertEqual(found.node, ToolVersion(major: 22, minor: 12, patch: 1))
        XCTAssertTrue(found.hasNode)
        XCTAssertFalse(found.hasPnpm)
        XCTAssertFalse(found.isReady)
    }

    func testProjectNamesAndIds() {
        XCTAssertEqual(ProjectsFile.slug("My Web App"), "my-web-app")
        XCTAssertEqual(ProjectsFile.slug("  Café_Ölmühle!! "), "cafe-olmuhle")
        XCTAssertEqual(ProjectsFile.slug("🚀"), "project")
        XCTAssertEqual(ProjectsFile.uniqueId(for: "App", taken: ["app", "app-2"]), "app-3")
        XCTAssertEqual(ProjectsFile.uniqueId(for: "App", taken: ["other"]), "app")
        XCTAssertEqual(ProjectsFile.displayName(for: URL(fileURLWithPath: "/Users/me/code/webapp/")), "webapp")
    }

    func testAddingFoldersKeepsIdsUniqueAndSkipsDuplicates() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let folders = [
            home.appendingPathComponent("code/app"),
            URL(fileURLWithPath: "/Volumes/Work/app"),
            home.appendingPathComponent("code/app"),
            URL(fileURLWithPath: "/Volumes/Work/Notes App"),
        ]
        let projects = ProjectsFile.adding(folders, to: [])
        XCTAssertEqual(projects.map(\.id), ["app", "app-2", "notes-app"])
        XCTAssertEqual(projects.map(\.name), ["app", "app", "Notes App"])
        XCTAssertEqual(projects[0].path, "~/code/app")
        XCTAssertEqual(projects[1].path, "/Volumes/Work/app")
        XCTAssertTrue(projects.allSatisfy { $0.agents == ["dev", "tester", "reviewer"] })
        XCTAssertEqual(Set(projects.map(\.id)).count, projects.count)
        XCTAssertEqual(ProjectsFile.adding([URL(fileURLWithPath: "/Volumes/Work/app")], to: projects).count, 3)
    }

    func testProjectsFileRoundTripsInTheHostShape() throws {
        let folder = try temporaryFolder()
        let file = folder.appendingPathComponent("nested/projects.json")
        let projects = [Project(id: "app", name: "App", path: "~/code/app", agents: ["dev", "reviewer"])]
        try ProjectsFile.write(projects, to: file)
        let data = try Data(contentsOf: file)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        XCTAssertEqual(json.first?["id"] as? String, "app")
        XCTAssertEqual(json.first?["path"] as? String, "~/code/app")
        XCTAssertEqual(json.first?["additionalDirectories"] as? [String], [])
        XCTAssertEqual(json.first?["agents"] as? [String], ["dev", "reviewer"])
        XCTAssertEqual(ProjectsFile.read(file), projects)
        XCTAssertTrue(String(decoding: data, as: UTF8.self).hasSuffix("\n"))
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("\\/"))
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: file.deletingLastPathComponent().path)
        XCTAssertEqual(leftovers, ["projects.json"])
    }

    func testRoleCatalogFallsBackToTheDefaults() throws {
        let folder = try temporaryFolder()
        let roles = folder.appendingPathComponent("roles.json")
        XCTAssertEqual(RoleCatalog.load(from: [roles]).map(\.id), RoleCatalog.fallback.map(\.id))
        try #"[{"id":"dev","name":"Builder","systemPrompt":"x","tools":[]}]"#.write(to: roles, atomically: true, encoding: .utf8)
        XCTAssertEqual(RoleCatalog.load(from: [folder.appendingPathComponent("missing.json"), roles]).map(\.name), ["Builder"])
        let repoRoles = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("roles.json")
        XCTAssertEqual(RoleCatalog.load(from: [repoRoles]).map(\.id), RoleCatalog.fallback.map(\.id))
    }

    @MainActor
    func testProjectsEditorEditsAndSavesOnlyWhenEditable() async throws {
        let folder = try temporaryFolder()
        let location = ProjectsLocation(file: folder.appendingPathComponent("projects.json"), roleFiles: [], isEditable: true)
        let editor = ProjectsEditor()
        await editor.load(location)
        XCTAssertTrue(editor.projects.isEmpty)
        XCTAssertEqual(editor.defaultRoles, ["dev", "tester", "reviewer"])
        editor.add([folder.appendingPathComponent("Site")])
        let project = try XCTUnwrap(editor.projects.first)
        editor.toggle(role: "tester", in: project)
        editor.toggle(role: "reviewer", in: project)
        editor.toggle(role: "dev", in: editor.projects[0])
        XCTAssertEqual(editor.projects[0].agents, ["dev"])
        editor.rename(editor.projects[0], to: "   ")
        XCTAssertTrue(editor.hasChanges)
        let saved = await editor.save()
        XCTAssertTrue(saved)
        XCTAssertFalse(editor.hasChanges)
        XCTAssertEqual(ProjectsFile.read(location.file)?.first?.name, "Site")
        let again = await editor.save()
        XCTAssertFalse(again)

        let readOnly = ProjectsEditor()
        await readOnly.load(ProjectsLocation(file: location.file, roleFiles: [], isEditable: false))
        readOnly.add([folder.appendingPathComponent("Other")])
        XCTAssertEqual(readOnly.projects.count, 1)
    }

    func testProjectsLocationFollowsTheSource() throws {
        let bundled = try bundledHost()
        let home = URL(fileURLWithPath: "/tmp/switchboard-home")
        let inHome = try XCTUnwrap(ProjectsLocation(source: .bundled(bundled, home: home)))
        XCTAssertEqual(inHome.file.path, "/tmp/switchboard-home/projects.json")
        XCTAssertEqual(inHome.roleFiles, [home.appendingPathComponent("roles.json"), bundled.roles])
        XCTAssertTrue(inHome.isEditable)
        let inRepo = try XCTUnwrap(ProjectsLocation(source: .repo(folder: "/Users/me/code/switchboard")))
        XCTAssertEqual(inRepo.file.path, "/Users/me/code/switchboard/projects.json")
        XCTAssertFalse(inRepo.isEditable)
        XCTAssertNil(ProjectsLocation(source: nil))
    }

    func testAccessTokensAreRandomBase64URL() throws {
        let first = try XCTUnwrap(AccessToken.make())
        let second = try XCTUnwrap(AccessToken.make())
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first.count, 43)
        XCTAssertNil(first.rangeOfCharacter(from: CharacterSet(charactersIn: "+/=")))
        XCTAssertEqual(AccessToken.base64URL(Data([0xfb, 0xff, 0xfe])), "-__-")
    }

    func testHomeFolderIsPrivateAndKeepsAnExistingToken() throws {
        let home = try temporaryFolder().appendingPathComponent("Switchboard")
        try SwitchboardHome.prepare(home)
        let env = home.appendingPathComponent(".env")
        XCTAssertEqual(try permissions(home), 0o700)
        XCTAssertEqual(try permissions(env), 0o600)
        let token = try XCTUnwrap(EnvFile.token(inFolder: home.path))
        XCTAssertGreaterThanOrEqual(token.count, 24)
        try SwitchboardHome.prepare(home)
        XCTAssertEqual(EnvFile.token(inFolder: home.path), token)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: home.path), [".env"])
    }

    func testHomeFolderAddsATokenToAnExistingEnvFile() throws {
        let home = try temporaryFolder()
        let env = home.appendingPathComponent(".env")
        try "SWITCHBOARD_PORT=4391".write(to: env, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: env.path)
        try SwitchboardHome.prepare(home)
        let values = EnvFile.values(inFolder: home.path)
        XCTAssertEqual(values[EnvFile.portKey], "4391")
        XCTAssertNotNil(values[EnvFile.tokenKey])
        XCTAssertEqual(try permissions(env), 0o600)
        XCTAssertEqual(try permissions(home), 0o700)
    }

    func testStandardHomeIsInApplicationSupport() {
        XCTAssertTrue(SwitchboardHome.standard.path.hasSuffix("Library/Application Support/Switchboard"))
    }

    func testOnboardingSettingsUseTheirOwnKeys() {
        let suite = "switchboard.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        XCTAssertFalse(settings.hasCompletedOnboarding)
        XCTAssertNil(settings.hostSource)
        settings.hasCompletedOnboarding = true
        settings.hostSource = HostSourceKind.bundled.rawValue
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertTrue(reloaded.hasCompletedOnboarding)
        XCTAssertEqual(reloaded.hostSource, "bundled")
    }

    func testChecklistWhileChecking() {
        let checks = SetupChecklist.checks(for: nil)
        XCTAssertEqual(checks.map(\.kind), SetupCheck.Kind.allCases)
        XCTAssertTrue(checks.allSatisfy { $0.level == .checking && $0.action == nil })
        XCTAssertFalse(SetupChecklist.requiredPassed(checks))
    }

    func testChecklistOnAFreshMac() {
        var snapshot = SystemSnapshot()
        snapshot.runtime = .bundled
        snapshot.claudePath = "/Applications/Switchboard.app/Contents/Resources/Host/claude"
        snapshot.notifications = .notDetermined
        let checks = SetupChecklist.checks(for: snapshot)
        let byKind = Dictionary(uniqueKeysWithValues: checks.map { ($0.kind, $0) })
        XCTAssertEqual(byKind[.host]?.level, .ready)
        XCTAssertEqual(byKind[.claude]?.level, .needed)
        XCTAssertEqual(byKind[.claude]?.action, .signIn)
        XCTAssertEqual(byKind[.claudeApp]?.level, .optional)
        XCTAssertEqual(byKind[.claudeApp]?.action, .getClaude)
        XCTAssertEqual(byKind[.tailscale]?.action, .getTailscale)
        XCTAssertEqual(byKind[.notifications]?.action, .allowNotifications)
        XCTAssertFalse(SetupChecklist.requiredPassed(checks))
        XCTAssertEqual(checks.filter(\.isRequired).map(\.kind), [.host, .claude])
        XCTAssertTrue(checks.filter { !$0.isRequired }.allSatisfy { $0.level != .needed })
    }

    func testChecklistWhenEverythingIsReady() {
        var snapshot = SystemSnapshot()
        snapshot.runtime = .repo(RepoToolchain(node: ToolVersion("v24.2.0"), hasNode: true, hasPnpm: true))
        snapshot.isClaudeSignedIn = true
        snapshot.claudeApp = AppPresence(isInstalled: true, isRunning: true)
        snapshot.tailscale = AppPresence(isInstalled: true, isRunning: true)
        snapshot.tailscaleAddress = "100.101.102.103"
        snapshot.notifications = .allowed
        let checks = SetupChecklist.checks(for: snapshot)
        XCTAssertTrue(checks.allSatisfy { $0.level == .ready })
        XCTAssertTrue(SetupChecklist.requiredPassed(checks))
        XCTAssertTrue(checks.first { $0.kind == .tailscale }?.detail.contains("100.101.102.103") == true)
        XCTAssertTrue(checks.first { $0.kind == .host }?.detail.contains("24.2.0") == true)
    }

    func testChecklistExplainsTheRepoToolchain() {
        func host(_ tools: RepoToolchain, running: Bool = false) -> SetupCheck {
            var snapshot = SystemSnapshot()
            snapshot.runtime = .repo(tools)
            snapshot.isHostRunning = running
            snapshot.port = 4317
            return SetupChecklist.host(snapshot)
        }
        XCTAssertEqual(host(RepoToolchain()).action, .getNode)
        XCTAssertEqual(host(RepoToolchain(node: ToolVersion("v20.0.0"), hasNode: true, hasPnpm: true)).action, .getNode)
        XCTAssertTrue(host(RepoToolchain(node: ToolVersion("v20.0.0"), hasNode: true, hasPnpm: true)).detail.contains("20.0.0"))
        XCTAssertEqual(host(RepoToolchain(node: ToolVersion("v24.0.0"), hasNode: true, hasPnpm: false)).action, .getPnpm)
        XCTAssertEqual(host(RepoToolchain(), running: true).level, .ready)
        XCTAssertEqual(host(RepoToolchain(), running: true).detail, "Running on port 4317.")
        var missing = SystemSnapshot()
        missing.runtime = .missing
        XCTAssertEqual(SetupChecklist.host(missing).level, .needed)
    }

    func testChecklistTailscaleAndNotificationStates() {
        var snapshot = SystemSnapshot()
        snapshot.tailscale = AppPresence(isInstalled: true, isRunning: false)
        XCTAssertEqual(SetupChecklist.tailscale(snapshot).action, .openTailscale)
        snapshot.tailscale.isRunning = true
        XCTAssertTrue(SetupChecklist.tailscale(snapshot).detail.contains("not connected"))
        snapshot.notifications = .denied
        XCTAssertEqual(SetupChecklist.notifications(snapshot).action, .openNotificationSettings)
        snapshot.notifications = .unknown
        XCTAssertEqual(SetupChecklist.notifications(snapshot).level, .checking)
        snapshot.claudeApp = AppPresence(isInstalled: true, isRunning: false)
        XCTAssertEqual(SetupChecklist.claudeApp(snapshot).action, .openClaude)
        XCTAssertNil(snapshot.claudePath)
        XCTAssertEqual(SetupChecklist.claude(snapshot).action, .getClaudeCode)
    }

    func testCheckActionsLinkToTheRightPages() {
        XCTAssertEqual(CheckAction.getTailscale.link?.absoluteString, "https://tailscale.com/download/mac")
        XCTAssertEqual(CheckAction.getClaude.link?.absoluteString, "https://claude.ai/download")
        XCTAssertNil(CheckAction.signIn.link)
        XCTAssertEqual(CheckAction.openTailscale.title, "Open Tailscale")
    }

    func testOnboardingStepsRunInOrder() {
        XCTAssertEqual(OnboardingStep.allCases.count, 6)
        XCTAssertEqual(OnboardingStep.welcome.next, .checks)
        XCTAssertNil(OnboardingStep.done.next)
        XCTAssertNil(OnboardingStep.welcome.previous)
        XCTAssertEqual(HostPhase(.failed("x"), ownsProcess: false), .failed("x"))
        XCTAssertEqual(HostPhase(.running, ownsProcess: true), .running(owned: true))
        XCTAssertEqual(HostPhase(.stopping, ownsProcess: true), .working)
    }

    @MainActor
    func testOnboardingFinishMarksCompletionAndRemembersTheSource() throws {
        let store = Fixtures.store()
        let bundled = try bundledHost()
        let host = HostController(settings: store.settings, bundled: bundled, home: try temporaryFolder())
        let model = OnboardingModel(host: host, settings: store.settings, checks: SystemChecks(host: nil, probe: nil), projects: ProjectsEditor())
        var finished = false
        model.onFinish = { finished = true }
        model.move(to: .phone)
        XCTAssertTrue(model.isForward)
        model.goBack()
        XCTAssertEqual(model.step, .host)
        XCTAssertFalse(model.isForward)
        model.finish()
        XCTAssertTrue(finished)
        XCTAssertTrue(store.settings.hasCompletedOnboarding)
        XCTAssertEqual(store.settings.hostSource, "bundled")
        model.restart()
        XCTAssertEqual(model.step, .welcome)
    }

    func testExistingUsersSkipOnboardingButNewUsersKeepIt() {
        func defaults() -> UserDefaults {
            let suite = "switchboard.tests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite) ?? .standard
            defaults.removePersistentDomain(forName: suite)
            return defaults
        }
        let existing = defaults()
        existing.set("/Users/me/Developer/switchboard", forKey: "repoFolder")
        XCTAssertTrue(AppSettings(defaults: existing).hasCompletedOnboarding)

        let connected = defaults()
        connected.set("http://127.0.0.1:4317", forKey: "hostURL")
        XCTAssertTrue(AppSettings(defaults: connected).hasCompletedOnboarding)

        let fresh = defaults()
        let first = AppSettings(defaults: fresh)
        XCTAssertFalse(first.hasCompletedOnboarding)
        first.repoFolder = "/Users/me/Developer/switchboard"
        XCTAssertFalse(AppSettings(defaults: fresh).hasCompletedOnboarding)
    }

    @MainActor
    func testUnreadableProjectsFileIsNeverOverwritten() async throws {
        let file = try temporaryFolder().appendingPathComponent("projects.json")
        let original = "[{\"id\": \"webapp\", \"name\": "
        try original.write(to: file, atomically: true, encoding: .utf8)
        let editor = ProjectsEditor()
        await editor.load(ProjectsLocation(file: file, roleFiles: [], isEditable: true))
        XCTAssertNotNil(editor.readFailure)
        XCTAssertFalse(editor.isEditable)
        editor.add([try temporaryFolder()])
        let saved = await editor.save()
        XCTAssertFalse(saved)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), original)

        try FileManager.default.removeItem(at: file)
        await editor.load(ProjectsLocation(file: file, roleFiles: [], isEditable: true))
        XCTAssertNil(editor.readFailure)
        XCTAssertTrue(editor.isEditable)
        XCTAssertTrue(editor.projects.isEmpty)
    }

    func testHostFailureShowsTheErrorLineInsteadOfRepeatingTheTitle() {
        let stopped = "The host stopped while starting. \(HostController.logHint)"
        let log = ["Starting the built-in host", "Error: projects.json: unknown role \"designer\"", "    at loadProjects"]
        XCTAssertEqual(HostStep.failureDetail(stopped, log: log), "projects.json: unknown role \"designer\"")
        XCTAssertEqual(HostStep.failureDetail(stopped, log: ["Starting the built-in host"]), "Here is the end of its log. Fix the problem, then try again.")
        XCTAssertEqual(HostStep.failureDetail(HostController.missingSource, log: log), HostController.missingSource)
    }
}
