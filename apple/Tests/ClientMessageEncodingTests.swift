import XCTest

final class ClientMessageEncodingTests: XCTestCase {
    private func fields(_ message: ClientMessage) throws -> [String: String] {
        let data = try JSONCoding.encoder.encode(message)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
    }

    func testEveryMessage() throws {
        XCTAssertEqual(try fields(.auth(token: "secret")), ["type": "auth", "token": "secret"])
        XCTAssertEqual(try fields(.chatSend(agentId: "a1", text: "hi")), ["type": "chat.send", "agentId": "a1", "text": "hi"])
        XCTAssertEqual(try fields(.historyGet(agentId: "a1")), ["type": "history.get", "agentId": "a1"])
        XCTAssertEqual(try fields(.agentStop(agentId: "a1")), ["type": "agent.stop", "agentId": "a1"])
        XCTAssertEqual(try fields(.queueRemove(agentId: "a1", id: "q1")), ["type": "queue.remove", "agentId": "a1", "id": "q1"])
        XCTAssertEqual(
            try fields(.approvalRespond(approvalId: "ap1", decision: .allow, scope: .turn)),
            ["type": "approval.respond", "approvalId": "ap1", "decision": "allow", "scope": "turn"]
        )
    }
}
