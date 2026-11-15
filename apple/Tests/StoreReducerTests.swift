import XCTest

@MainActor
final class StoreReducerTests: XCTestCase {
    func testBootstrapFillsTheStoreAndPicksAProject() throws {
        let store = Fixtures.store()
        store.apply(try Fixtures.message(Fixtures.bootstrap))
        XCTAssertTrue(store.isReady)
        XCTAssertEqual(store.selectedProjectId, "work")
        XCTAssertEqual(store.agents.count, 2)
        XCTAssertEqual(store.approvals.map(\.id), ["ap1"])
        XCTAssertEqual(store.hostInfo?.tailscaleUrl, "http://100.64.0.7:4317")
        XCTAssertEqual(store.agents(in: "side").map(\.name), ["Maya", "Nora"])
        XCTAssertEqual(store.roles(for: try XCTUnwrap(store.project(id: "side"))).map(\.id), ["ideation", "dev"])
        XCTAssertEqual(store.summary, "1 working, 1 idle")
    }

    func testBootstrapKeepsAKnownProjectAndDropsAMissingAgent() throws {
        let store = Fixtures.store()
        store.selectedProjectId = "side"
        store.selectedAgentId = "gone"
        store.apply(try Fixtures.message(Fixtures.bootstrap))
        XCTAssertEqual(store.selectedProjectId, "side")
        XCTAssertNil(store.selectedAgentId)
    }

    func testDeltasBuildADraftAndTheItemReplacesIt() throws {
        let store = Fixtures.store()
        store.apply(.chatDelta(agentId: "a1", itemId: "m1", text: "Hel"))
        store.apply(.chatDelta(agentId: "a1", itemId: "m1", text: "lo"))
        store.apply(.chatDelta(agentId: "a1", itemId: "m2", text: "Second"))
        XCTAssertEqual(store.drafts(for: "a1"), [ChatDraft(id: "m1", text: "Hello"), ChatDraft(id: "m2", text: "Second")])
        let item = ChatItem(id: "m1", agentId: "a1", role: .assistant, content: .text("Hello there"), createdAt: Date())
        store.apply(.chatItem(item))
        XCTAssertEqual(store.drafts(for: "a1"), [ChatDraft(id: "m2", text: "Second")])
        XCTAssertEqual(store.items(for: "a1"), [item])
    }

    func testItemsAreUpsertedById() throws {
        let store = Fixtures.store()
        store.apply(try Fixtures.message(Fixtures.textItem))
        store.apply(try Fixtures.message(Fixtures.toolItem))
        store.apply(try Fixtures.message(Fixtures.finishedToolItem))
        XCTAssertEqual(store.items(for: "a1").map(\.id), ["3a91ccf5", "t1"])
        guard case .tool(let tool) = store.items(for: "a1")[1].content else { return XCTFail("Expected a tool row") }
        XCTAssertEqual(tool.status, .done)
    }

    func testHistoryReplacesItemsAndDrafts() throws {
        let store = Fixtures.store()
        store.apply(.chatDelta(agentId: "a1", itemId: "old", text: "stale"))
        XCTAssertFalse(store.isHistoryLoaded("a1"))
        store.apply(try Fixtures.message(Fixtures.history))
        XCTAssertTrue(store.isHistoryLoaded("a1"))
        XCTAssertEqual(store.items(for: "a1").count, 3)
        XCTAssertEqual(store.drafts(for: "a1").map(\.id), ["d1"])
    }

    func testAgentUpsertAndRemoval() throws {
        let store = Fixtures.store()
        store.apply(.agentUpserted(Fixtures.agent(id: "a1")))
        store.apply(.agentUpserted(Fixtures.agent(id: "a2")))
        store.apply(.agentUpserted(Fixtures.agent(id: "a1", status: .working)))
        store.apply(try Fixtures.message(Fixtures.textItem))
        store.apply(try Fixtures.message(Fixtures.approvalRequested))
        store.selectedAgentId = "a1"
        XCTAssertEqual(store.agents["a1"]?.status, .working)
        store.apply(.agentRemoved(agentId: "a1"))
        XCTAssertEqual(Array(store.agents.keys), ["a2"])
        XCTAssertNil(store.selectedAgentId)
        XCTAssertTrue(store.items(for: "a1").isEmpty)
        XCTAssertTrue(store.approvals.isEmpty)
    }

    func testApprovalLifecycle() throws {
        let store = Fixtures.store()
        store.apply(.agentUpserted(Fixtures.agent(id: "a1", status: .waiting)))
        store.apply(try Fixtures.message(Fixtures.approvalRequested))
        store.apply(try Fixtures.message(Fixtures.approvalRequested))
        XCTAssertEqual(store.approvals.map(\.id), ["ap2"])
        XCTAssertEqual(store.approvals(for: "a1").count, 1)
        XCTAssertEqual(store.agent(for: store.approvals[0])?.id, "a1")
        XCTAssertTrue(store.isApprovalInputHeld)
        store.pendingAnswers["ap2"] = ApprovalAnswer(decision: .allow)
        XCTAssertTrue(store.isAnswered(store.approvals[0]))
        store.apply(try Fixtures.message(Fixtures.approvalResolved))
        XCTAssertTrue(store.approvals.isEmpty)
        XCTAssertNil(store.pendingAnswers["ap2"])
        XCTAssertFalse(store.isApprovalInputHeld)
    }

    func testBootstrapKeepsAnswersForPendingApprovalsOnly() throws {
        let store = Fixtures.store()
        store.pendingAnswers = ["ap1": ApprovalAnswer(decision: .allow, scope: .turn), "settled": ApprovalAnswer(decision: .deny)]
        store.apply(try Fixtures.message(Fixtures.bootstrap))
        XCTAssertEqual(store.pendingAnswers, ["ap1": ApprovalAnswer(decision: .allow, scope: .turn)])
        XCTAssertEqual(ApprovalAnswer(decision: .deny).message(for: "ap1"), .approvalRespond(approvalId: "ap1", decision: .deny, scope: .once))
    }

    func testApprovalInputIsHeldBrieflyAfterTheListChanges() async throws {
        let store = Fixtures.store()
        store.apply(try Fixtures.message(Fixtures.approvalRequested))
        XCTAssertTrue(store.isApprovalInputHeld)
        store.respond(to: store.approvals[0], decision: .allow)
        XCTAssertNil(store.notice)
        try await Task.sleep(for: .seconds(AppStore.approvalHoldTime + 0.4))
        XCTAssertFalse(store.isApprovalInputHeld)
        store.respond(to: store.approvals[0], decision: .allow)
        XCTAssertNotNil(store.notice)
        XCTAssertTrue(store.pendingAnswers.isEmpty)
    }

    func testReconnectKeepsMessagesUntilHistoryArrives() throws {
        let store = Fixtures.store()
        store.apply(try Fixtures.message(Fixtures.history))
        store.apply(try Fixtures.message(Fixtures.bootstrap))
        XCTAssertFalse(store.isHistoryLoaded("a1"))
        XCTAssertEqual(store.items(for: "a1").count, 3)
    }

    func testErrorBecomesANoticeAndUnknownIsIgnored() throws {
        let store = Fixtures.store()
        store.apply(.unknown(type: "future"))
        XCTAssertNil(store.notice)
        store.apply(.error(message: "Agent not found"))
        XCTAssertEqual(store.notice, "Agent not found")
        store.dismissNotice()
        XCTAssertNil(store.notice)
    }

    func testUrgencyOrder() {
        let store = Fixtures.store()
        store.apply(.agentUpserted(Fixtures.agent(id: "idle-old", status: .idle, lastActivity: 10)))
        store.apply(.agentUpserted(Fixtures.agent(id: "idle-new", status: .idle, lastActivity: 20)))
        store.apply(.agentUpserted(Fixtures.agent(id: "working", status: .working)))
        store.apply(.agentUpserted(Fixtures.agent(id: "error", status: .error)))
        store.apply(.agentUpserted(Fixtures.agent(id: "waiting", status: .waiting)))
        XCTAssertEqual(store.agentsByUrgency.map(\.id), ["waiting", "error", "working", "idle-new", "idle-old"])
        XCTAssertEqual(store.waitingCount, 1)
        XCTAssertEqual(store.workingCount, 1)
    }

    func testSelectionAndOfflineSend() {
        let store = Fixtures.store()
        store.apply(.agentUpserted(Fixtures.agent(id: "a1", project: "side")))
        store.openAgent(id: "a1")
        XCTAssertEqual(store.selectedProjectId, "side")
        XCTAssertEqual(store.selectedAgentId, "a1")
        XCTAssertEqual(store.settings.lastProjectId, "side")
        store.selectProject("work")
        XCTAssertNil(store.selectedAgentId)
        XCTAssertFalse(store.send("   ", to: "a1"))
        XCTAssertNil(store.notice)
        XCTAssertFalse(store.send("hello", to: "a1"))
        XCTAssertNotNil(store.notice)
    }
}
