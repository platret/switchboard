import XCTest

final class ServerMessageDecodingTests: XCTestCase {
    func testSimpleMessages() throws {
        XCTAssertEqual(try Fixtures.message(#"{"type":"auth.ok"}"#), .authOk)
        XCTAssertEqual(try Fixtures.message(#"{"type":"ping"}"#), .ping)
        XCTAssertEqual(try Fixtures.message(#"{"type":"agent.removed","agentId":"a1"}"#), .agentRemoved(agentId: "a1"))
        XCTAssertEqual(try Fixtures.message(#"{"type":"chat.delta","agentId":"a1","itemId":"d1","text":"Hel"}"#), .chatDelta(agentId: "a1", itemId: "d1", text: "Hel"))
        XCTAssertEqual(try Fixtures.message(#"{"type":"error","message":"Invalid message"}"#), .error(message: "Invalid message"))
    }

    func testUnknownTypeIsKept() throws {
        XCTAssertEqual(try Fixtures.message(#"{"type":"usage.updated","tokens":12}"#), .unknown(type: "usage.updated"))
        XCTAssertNil(ServerMessage.parse("not json"))
        XCTAssertNil(ServerMessage.parse(#"{"type":"chat.delta"}"#))
    }

    func testBootstrap() throws {
        guard case .bootstrap(let bootstrap) = try Fixtures.message(Fixtures.bootstrap) else { return XCTFail("Expected a bootstrap") }
        XCTAssertEqual(bootstrap.projects.map(\.id), ["work", "side"])
        XCTAssertEqual(bootstrap.projects[0].additionalDirectories, ["/Users/me/code/shared-lib"])
        XCTAssertEqual(bootstrap.roles[0].starters.count, 2)
        XCTAssertEqual(bootstrap.roles[1].description, "")
        XCTAssertEqual(bootstrap.roles[1].model, "claude-opus-4-5")
        XCTAssertEqual(bootstrap.host?.tailscaleUrl, "http://100.64.0.7:4317")
        let nora = try XCTUnwrap(bootstrap.agents.last)
        XCTAssertEqual(nora.status, .working)
        XCTAssertEqual(nora.activity, "Bash: pnpm test")
        XCTAssertEqual(nora.queue, [QueuedMessage(id: "q1", text: "then run the linter")])
        XCTAssertEqual(nora.trustedTools, ["Edit"])
        XCTAssertNil(nora.sessionId)
        XCTAssertEqual(nora.createdAt.timeIntervalSince1970, 1_794_703_283.071, accuracy: 0.001)
        let approval = try XCTUnwrap(bootstrap.approvals.first)
        XCTAssertEqual(approval.detail, .command("pnpm test", runsInBackground: true))
        XCTAssertEqual(approval.expiresAt.timeIntervalSince(approval.createdAt), 600, accuracy: 0.001)
        XCTAssertFalse(approval.supportsTurnScope)
    }

    func testBootstrapWithoutHostAndWithUnknownStatus() throws {
        let json = #"{"type":"bootstrap","bootstrap":{"projects":[],"roles":[],"agents":[{"id":"a","name":"A","projectId":"p","role":"dev","sessionId":null,"status":"sleeping","createdAt":1,"lastActivityAt":2,"preview":null}],"approvals":[]}}"#
        guard case .bootstrap(let bootstrap) = try Fixtures.message(json) else { return XCTFail("Expected a bootstrap") }
        XCTAssertNil(bootstrap.host)
        XCTAssertEqual(bootstrap.agents.first?.status, .idle)
        XCTAssertEqual(bootstrap.agents.first?.queue, [])
    }

    func testChatItems() throws {
        guard case .chatItem(let text) = try Fixtures.message(Fixtures.textItem) else { return XCTFail("Expected an item") }
        XCTAssertEqual(text.role, .user)
        XCTAssertEqual(text.content, .text("hi there"))
        guard case .chatItem(let item) = try Fixtures.message(Fixtures.toolItem), case .tool(let tool) = item.content else { return XCTFail("Expected a tool item") }
        XCTAssertEqual(tool.name, "Edit")
        XCTAssertEqual(tool.status, .running)
        XCTAssertNil(tool.result)
        XCTAssertEqual(tool.input.string("file_path"), "/repo/src/app.ts")
        XCTAssertEqual(tool.input["nested"]?["list"], .array([.number(1), .number(2.5), .null, .string("x")]))
        XCTAssertFalse(tool.input.flag("replace_all"))
        guard case .chatItem(let done) = try Fixtures.message(Fixtures.finishedToolItem), case .tool(let finished) = done.content else { return XCTFail("Expected a tool item") }
        XCTAssertEqual(finished.status, .done)
        XCTAssertEqual(finished.result, "The file was updated.")
    }

    func testUnknownContentKindAndRole() throws {
        guard case .chatItem(let item) = try Fixtures.message(Fixtures.futureItem) else { return XCTFail("Expected an item") }
        XCTAssertEqual(item.content, .unknown(kind: "image"))
        XCTAssertEqual(item.role, .system)
    }

    func testHistorySkipsBrokenItems() throws {
        guard case .history(let agentId, let history) = try Fixtures.message(Fixtures.history) else { return XCTFail("Expected a history") }
        XCTAssertEqual(agentId, "a1")
        XCTAssertEqual(history.items.map(\.id), ["i1", "i2", "i3"])
        XCTAssertEqual(history.items[1].content, .notice("Stopped"))
        XCTAssertEqual(history.items[2].content, .error("Claude reported: overloaded"))
        XCTAssertEqual(history.drafts, [ChatDraft(id: "d1", text: "Thinking about")])
    }

    func testApprovals() throws {
        guard case .approvalRequested(let approval) = try Fixtures.message(Fixtures.approvalRequested) else { return XCTFail("Expected an approval") }
        XCTAssertEqual(approval.detail, .write(path: "/repo/notes.md", content: "# Notes"))
        XCTAssertEqual(approval.action, "write a file")
        XCTAssertTrue(approval.supportsTurnScope)
        let resolution = ApprovalResolution(approvalId: "ap2", agentId: "a1", decision: .deny, by: .timeout)
        XCTAssertEqual(try Fixtures.message(Fixtures.approvalResolved), .approvalResolved(resolution))
    }

    func testApprovalDetailFallsBackToJSON() throws {
        let approval = Approval(id: "x", agentId: "a", toolName: "WebFetch", input: .object(["url": .string("https://example.test/a")]))
        XCTAssertEqual(approval.detail, .other(json: "{\n  \"url\" : \"https://example.test/a\"\n}"))
        XCTAssertEqual(approval.action, "fetch a web page")
        XCTAssertEqual(Approval(id: "y", agentId: "a", toolName: "mcp__x").action, "use mcp__x")
    }
}
