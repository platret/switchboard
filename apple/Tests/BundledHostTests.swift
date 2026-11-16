import XCTest

@MainActor
final class BundledHostTests: XCTestCase {
    struct FakeInstall {
        let host: BundledHost
        let home: URL
    }

    static func install(port: Int, script: String) throws -> FakeInstall {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("switchboard-bundle-\(UUID().uuidString)")
        let hostFolder = root.appendingPathComponent("Host")
        let home = root.appendingPathComponent("Home")
        try FileManager.default.createDirectory(at: hostFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        try "#!/bin/zsh\n\(script)\n".write(to: hostFolder.appendingPathComponent("start"), atomically: true, encoding: .utf8)
        try "\(EnvFile.portKey)=\(port)\n".write(to: home.appendingPathComponent(".env"), atomically: true, encoding: .utf8)
        return FakeInstall(host: try XCTUnwrap(BundledHost(root: hostFolder)), home: home)
    }

    static func controller(for install: FakeInstall) -> HostController {
        let settings = Fixtures.store().settings
        settings.hostSource = HostSourceKind.bundled.rawValue
        return HostController(settings: settings, bundled: install.host, home: install.home)
    }

    func testBundledHostStartsInItsHomeAndStops() async throws {
        let port = 4391
        let install = try BundledHostTests.install(port: port, script: """
        print -r -- "$SWITCHBOARD_HOME|$PWD" > launched.txt
        exec python3 -m http.server \(port) --bind 127.0.0.1
        """)
        let controller = BundledHostTests.controller(for: install)
        await controller.start()
        XCTAssertEqual(controller.source?.kind, .bundled)
        XCTAssertEqual(controller.port, port)
        XCTAssertEqual(controller.state, .running)
        XCTAssertTrue(controller.ownsProcess)
        XCTAssertEqual(controller.log.lines.first, "Starting the built-in host")
        let launched = try String(contentsOf: install.home.appendingPathComponent("launched.txt"), encoding: .utf8).trimmingCharacters(in: .newlines)
        let parts = launched.split(separator: "|").map(String.init)
        XCTAssertEqual(parts.first, install.home.path)
        XCTAssertEqual(parts.last.map { URL(fileURLWithPath: $0).resolvingSymlinksInPath().path }, install.home.resolvingSymlinksInPath().path)
        XCTAssertNotNil(EnvFile.token(inFolder: install.home.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: install.home.appendingPathComponent(".env").path)
        XCTAssertEqual(attributes[.posixPermissions] as? Int, 0o600)
        let pids = await HostProbe.listenerPids(port: port)
        XCTAssertFalse(pids.isEmpty)
        await controller.stop()
        XCTAssertEqual(controller.state, .stopped)
        XCTAssertFalse(controller.ownsProcess)
        let remaining = await HostProbe.listenerPids(port: port)
        XCTAssertTrue(remaining.isEmpty)
    }

    func testBundledHostFailureKeepsTheLog() async throws {
        let install = try BundledHostTests.install(port: 4393, script: """
        print "Switchboard host 2.1.0"
        print "Error: SWITCHBOARD_TOKEN in .env must be at least 24 characters" >&2
        exit 1
        """)
        let controller = BundledHostTests.controller(for: install)
        await controller.start()
        try await Task.sleep(for: .milliseconds(300))
        guard case .failed(let message) = controller.state else { return XCTFail("Expected a failure, got \(controller.state)") }
        XCTAssertFalse(message.contains("pnpm"))
        XCTAssertTrue(controller.log.lines.contains { $0.contains("at least 24 characters") })
        XCTAssertFalse(controller.ownsProcess)
    }

    func testBundledHostReportsAHostThatRejectsItsToken() async throws {
        let port = 4396
        let install = try BundledHostTests.install(port: port, script: "exit 0")
        try SwitchboardHome.prepare(install.home)
        let server = Process()
        server.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        server.arguments = ["-c", """
        import http.server
        class Reject(http.server.BaseHTTPRequestHandler):
            def do_HEAD(self): self.send_response(200); self.end_headers()
            def do_GET(self): self.send_response(401); self.end_headers()
            def log_message(self, *args): pass
        http.server.HTTPServer(("127.0.0.1", \(port)), Reject).serve_forever()
        """]
        try server.run()
        defer { server.terminate(); server.waitUntilExit() }
        for _ in 0..<40 where await !HostProbe.isListening(port: port) {
            try await Task.sleep(for: .milliseconds(100))
        }
        let controller = BundledHostTests.controller(for: install)
        await controller.refresh()
        guard case .failed(let message) = controller.state else { return XCTFail("Expected a conflict, got \(controller.state)") }
        XCTAssertTrue(message.contains("Another host already uses port \(port)"))
        XCTAssertFalse(controller.ownsProcess)
        await controller.start()
        guard case .failed = controller.state else { return XCTFail("Start must not adopt the other host, got \(controller.state)") }
    }
}
