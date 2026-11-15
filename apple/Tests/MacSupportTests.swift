import XCTest

final class MacSupportTests: XCTestCase {
    func testTailscaleRange() {
        XCTAssertTrue(TailscaleAddress.isTailscale("100.127.255.254"))
        XCTAssertTrue(TailscaleAddress.isTailscale("100.64.0.1"))
        XCTAssertFalse(TailscaleAddress.isTailscale("100.128.0.1"))
        XCTAssertFalse(TailscaleAddress.isTailscale("192.168.1.10"))
        XCTAssertFalse(TailscaleAddress.isTailscale("100.64.0"))
        XCTAssertTrue(TailscaleAddress.interfaceAddresses().contains { $0.address == "127.0.0.1" })
    }

    func testRepoLocatorFindsACloneUnderTheHomeFolder() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let clone = home.appendingPathComponent("Desktop/Projects/switchboard")
        let package = clone.appendingPathComponent("package.json")
        try FileManager.default.createDirectory(at: clone.appendingPathComponent("host"), withIntermediateDirectories: true)
        XCTAssertNil(RepoLocator.find(home: home))
        try #"{"name":"something-else"}"#.write(to: package, atomically: true, encoding: .utf8)
        XCTAssertNil(RepoLocator.find(home: home))
        try #"{"name":"switchboard","private":true}"#.write(to: package, atomically: true, encoding: .utf8)
        XCTAssertEqual(RepoLocator.find(home: home), clone.path)
        let nearer = home.appendingPathComponent("code/switchboard")
        try FileManager.default.createDirectory(at: nearer.appendingPathComponent("host"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: package, to: nearer.appendingPathComponent("package.json"))
        XCTAssertEqual(RepoLocator.find(home: home), nearer.path)
    }

    func testSettingsStartWithoutARepoFolderAndKeepAStoredOne() {
        let suite = "switchboard.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        XCTAssertEqual(AppSettings(defaults: defaults).repoFolder, "")
        AppSettings(defaults: defaults).repoFolder = "/Users/me/code/switchboard"
        XCTAssertEqual(AppSettings(defaults: defaults).repoFolder, "/Users/me/code/switchboard")
        defaults.removePersistentDomain(forName: suite)
    }

    func testHostLogKeepsTheLastLines() {
        var log = HostLog()
        log.append("first li")
        log.append("ne\n\u{1B}[32msecond\u{1B}[0m line\r\npart")
        XCTAssertEqual(log.lines, ["first line", "second line"])
        for index in 0..<300 { log.note("line \(index)") }
        XCTAssertEqual(log.lines.count, HostLog.limit)
        XCTAssertEqual(log.lines.last, "line 299")
    }

    func testHostProcessCapturesOutput() async throws {
        let finished = expectation(description: "exit")
        let output = OutputBox()
        let process = HostProcess()
        try process.start(command: "echo hello from $PATH", folder: NSTemporaryDirectory()) { chunk in
            output.append(chunk)
        } onExit: { _ in
            finished.fulfill()
        }
        await fulfillment(of: [finished], timeout: 10)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(output.text.trimmingCharacters(in: .whitespacesAndNewlines), "hello from \(HostProcess.searchPath)")
    }

    private func folder(port: Int) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try "\(EnvFile.portKey)=\(port)\n".write(to: folder.appendingPathComponent(".env"), atomically: true, encoding: .utf8)
        return folder
    }

    @MainActor
    func testHostStartedEarlierIsAdoptedAndStopped() async throws {
        let port = 4398
        let settings = Fixtures.store().settings
        settings.repoFolder = try folder(port: port).path
        let earlier = HostProcess()
        try earlier.start(command: "python3 -m http.server \(port) --bind 127.0.0.1", folder: settings.repoFolder) { _ in } onExit: { _ in }
        let deadline = Date().addingTimeInterval(15)
        while !(await HostProbe.isListening(port: port)), Date() < deadline { try await Task.sleep(for: .milliseconds(100)) }
        let controller = HostController(settings: settings)
        await controller.refresh()
        XCTAssertEqual(controller.state, .running)
        XCTAssertFalse(controller.ownsProcess)
        settings.hostProcessGroup = earlier.group
        await controller.refresh()
        XCTAssertTrue(controller.ownsProcess)
        await controller.stop()
        XCTAssertEqual(controller.state, .stopped)
        XCTAssertFalse(earlier.isRunning)
        XCTAssertNil(settings.hostProcessGroup)
    }

    @MainActor
    func testOverlappingStartsLaunchOneProcess() async throws {
        let settings = Fixtures.store().settings
        settings.repoFolder = try folder(port: 4397).path
        let controller = HostController(settings: settings)
        async let first: Void = controller.start()
        async let second: Void = controller.start()
        _ = await (first, second)
        XCTAssertEqual(controller.log.lines.filter { $0.hasPrefix("Starting the host") }.count, 1)
        controller.releaseProcess()
    }
}

final class OutputBox: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""

    var text: String {
        lock.withLock { buffer }
    }

    func append(_ chunk: String) {
        lock.withLock { buffer += chunk }
    }
}
