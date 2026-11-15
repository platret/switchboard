import XCTest

@MainActor
final class LiveHostTests: XCTestCase {
    private static let envPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent(".env")
        .path

    private func liveEndpoint() async throws -> HostEndpoint {
        guard await HostProbe.isListening(port: HostEndpoint.defaultPort) else {
            throw XCTSkip("No Switchboard host answers on \(HostEndpoint.localhost). Start it with pnpm dev.")
        }
        return try XCTUnwrap(HostEndpoint(string: HostEndpoint.localhost))
    }

    private func token() async throws -> String {
        if let passed = ProcessInfo.processInfo.environment[EnvFile.tokenKey], !passed.isEmpty { return passed }
        let file = OutputBox()
        let path = LiveHostTests.envPath
        Thread.detachNewThread {
            file.append((try? String(contentsOfFile: path, encoding: .utf8)) ?? "")
        }
        let deadline = Date().addingTimeInterval(3)
        while file.text.isEmpty, Date() < deadline { try await Task.sleep(for: .milliseconds(50)) }
        guard let token = EnvFile.parse(file.text)[EnvFile.tokenKey], !token.isEmpty else {
            throw XCTSkip("The test runner may not read the repo .env yet. Run Scripts/test.sh, which passes the token in.")
        }
        return token
    }

    func testBootstrapArrivesFromTheLiveHost() async throws {
        let endpoint = try await liveEndpoint()
        let token = try await token()
        let client = SwitchboardClient()
        let arrived = expectation(description: "bootstrap")
        var received: Bootstrap?
        var states: [ConnectionState] = []
        client.onState = { states.append($0) }
        client.onMessage = { message in
            guard case .bootstrap(let bootstrap) = message, received == nil else { return }
            received = bootstrap
            arrived.fulfill()
        }
        client.connect(to: endpoint, token: token)
        await fulfillment(of: [arrived], timeout: 10)
        client.disconnect()
        XCTAssertNotNil(received)
        XCTAssertGreaterThanOrEqual(received?.roles.count ?? 0, 1)
        XCTAssertEqual(states, [.connecting, .connected])
    }

    func testWrongTokenIsRejectedWithoutRetrying() async throws {
        let endpoint = try await liveEndpoint()
        let client = SwitchboardClient()
        let rejected = expectation(description: "rejected")
        var states: [ConnectionState] = []
        client.onState = { state in
            states.append(state)
            if state == .tokenRejected { rejected.fulfill() }
        }
        client.connect(to: endpoint, token: "wrong-token-used-by-the-unit-tests")
        await fulfillment(of: [rejected], timeout: 10)
        try await Task.sleep(for: .seconds(1))
        XCTAssertEqual(states, [.connecting, .tokenRejected])
        XCTAssertFalse(client.send(.historyGet(agentId: "none")))
    }

    func testStoreConnectsAndLoadsHistory() async throws {
        let endpoint = try await liveEndpoint()
        let store = Fixtures.store()
        try store.saveConnection(host: "127.0.0.1", token: try await token())
        XCTAssertEqual(store.settings.hostURL, endpoint.displayString)
        let deadline = Date().addingTimeInterval(10)
        while !store.isReady, Date() < deadline { try await Task.sleep(for: .milliseconds(50)) }
        XCTAssertTrue(store.isReady)
        XCTAssertEqual(store.connection, .connected)
        XCTAssertEqual(store.selectedProject == nil, store.projects.isEmpty)
        if let agent = store.agentsByUrgency.first {
            store.selectAgent(agent.id)
            while !store.isHistoryLoaded(agent.id), Date() < deadline { try await Task.sleep(for: .milliseconds(50)) }
            XCTAssertTrue(store.isHistoryLoaded(agent.id))
        }
        store.disconnect()
    }

    func testHostProbeSeesTheLiveHost() async throws {
        _ = try await liveEndpoint()
        let pids = await HostProbe.listenerPids(port: HostEndpoint.defaultPort)
        XCTAssertFalse(pids.isEmpty)
        let controller = HostController(settings: Fixtures.store().settings)
        await controller.startIfNeeded()
        XCTAssertEqual(controller.state, .running)
        XCTAssertFalse(controller.ownsProcess)
    }
}
