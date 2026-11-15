import XCTest

final class ViewLogicTests: XCTestCase {
    private func item(_ id: String, _ role: ChatRole, _ content: ChatContent) -> ChatItem {
        ChatItem(id: id, agentId: "a1", role: role, content: content, createdAt: Date(timeIntervalSince1970: 1))
    }

    private func tool(_ id: String, _ status: ToolStatus = .done) -> ChatContent {
        .tool(ToolCall(toolUseId: id, name: "Bash", summary: "ls", input: .object(["command": .string("ls")]), status: status))
    }

    func testThreadGroupsConsecutiveToolsAndSkipsUnknownContent() {
        let items = [
            item("i1", .user, .text("go")),
            item("i2", .assistant, tool("t1")),
            item("i3", .assistant, .unknown(kind: "image")),
            item("i4", .assistant, tool("t2", .running)),
            item("i5", .assistant, .text("done")),
            item("i6", .assistant, tool("t3")),
        ]
        let entries = ChatEntry.thread(from: items)
        XCTAssertEqual(entries.map(\.id), ["i1", "tools-i2", "i5", "tools-i6"])
        guard case .tools(_, let calls) = entries[1] else { return XCTFail("Expected a tool group") }
        XCTAssertEqual(calls.map(\.toolUseId), ["t1", "t2"])
        XCTAssertEqual(ToolPresentation.overall(calls), .running)
    }

    func testToolPresentation() {
        XCTAssertEqual(ToolPresentation.title(for: "mcp__github__create_pull_request"), "create pull request")
        XCTAssertEqual(ToolPresentation.title(for: "Bash"), "Bash")
        XCTAssertEqual(ToolPresentation.symbol(for: "mcp__github__x"), "puzzlepiece.extension")
        let call = ToolCall(toolUseId: "t", name: "Bash", input: .object(["command": .string("pnpm test")]))
        XCTAssertEqual(ToolPresentation.detail(for: call), .command("pnpm test", runsInBackground: false))
        let denied = ToolCall(toolUseId: "d", name: "Edit", status: .denied)
        let failed = ToolCall(toolUseId: "e", name: "Read", status: .error)
        XCTAssertEqual(ToolPresentation.overall([call, failed, denied]), .denied)
        XCTAssertEqual(ToolPresentation.overall([call, failed]), .error)
        XCTAssertEqual(ToolPresentation.overall([call]), .done)
    }

    func testAgentNamingSuggestsAFreeName() {
        let role = Role(id: "dev", name: "Developer")
        XCTAssertEqual(AgentNaming.suggestion(for: role, taken: ["Leo"]), "Developer")
        XCTAssertEqual(AgentNaming.suggestion(for: role, taken: ["developer", "Developer 2"]), "Developer 3")
        XCTAssertTrue(AgentNaming.isValid(" Nora "))
        XCTAssertFalse(AgentNaming.isValid("   "))
        XCTAssertFalse(AgentNaming.isValid(String(repeating: "a", count: Agent.nameMaxLength + 1)))
    }

    func testMarkerDetectsStreamingAndNewRows() {
        let first = MessageListMarker(items: [item("i1", .assistant, .text("hi"))], drafts: [], approvals: [])
        let streamed = MessageListMarker(items: [item("i1", .assistant, .text("hi"))], drafts: [ChatDraft(id: "d", text: "abc")], approvals: [])
        let sent = MessageListMarker(items: [item("i1", .assistant, .text("hi")), item("i2", .user, .text("yo"))], drafts: [], approvals: [])
        XCTAssertNotEqual(first, streamed)
        XCTAssertFalse(streamed.addsRow(after: first))
        XCTAssertTrue(sent.addsRow(after: first))
        XCTAssertNotEqual(sent, first)
    }

    func testSummaryIsCompleteOnlyForAShortCommand() {
        let short = Approval(id: "a", agentId: "a1", toolName: "Bash", summary: "pnpm test", input: .object(["command": .string("pnpm  test")]))
        let clipped = Approval(id: "b", agentId: "a1", toolName: "Bash", summary: "pnpm lint && rm", input: .object(["command": .string("pnpm lint && rm -rf build")]))
        let write = Approval(id: "c", agentId: "a1", toolName: "Write", summary: "notes.md", input: .object(["file_path": .string("notes.md"), "content": .string("x")]))
        XCTAssertTrue(short.isSummaryComplete)
        XCTAssertFalse(clipped.isSummaryComplete)
        XCTAssertFalse(write.isSummaryComplete)
    }

    func testTurnScopeFollowsTheHostWhenItSaysSo() throws {
        let json = #"{"type":"approval.requested","approval":{"id":"ap9","agentId":"a1","toolName":"Edit","summary":"x","input":{},"turnTrust":false,"createdAt":1,"expiresAt":2}}"#
        guard case .approvalRequested(let outside) = try Fixtures.message(json) else { return XCTFail("Expected an approval") }
        XCTAssertFalse(outside.supportsTurnScope)
        XCTAssertTrue(Approval(id: "a", agentId: "a1", toolName: "Edit").supportsTurnScope)
        XCTAssertFalse(Approval(id: "b", agentId: "a1", toolName: "Bash").supportsTurnScope)
    }
}
