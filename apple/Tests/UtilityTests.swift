import XCTest

final class UtilityTests: XCTestCase {
    func testHostEndpoint() throws {
        XCTAssertEqual(HostEndpoint(string: " 100.64.0.7 ")?.displayString, "http://100.64.0.7:4317")
        XCTAssertEqual(HostEndpoint(string: "mac.tailnet.ts.net:5000")?.displayString, "http://mac.tailnet.ts.net:5000")
        XCTAssertEqual(HostEndpoint(string: "https://mac.tailnet.ts.net/")?.displayString, "https://mac.tailnet.ts.net")
        XCTAssertNil(HostEndpoint(string: ""))
        XCTAssertNil(HostEndpoint(string: "ftp://host"))
        let endpoint = try XCTUnwrap(HostEndpoint(string: "http://127.0.0.1:4317"))
        XCTAssertEqual(endpoint.webSocketURL?.absoluteString, "ws://127.0.0.1:4317/ws")
        XCTAssertEqual(endpoint.apiURL("agents/abc").absoluteString, "http://127.0.0.1:4317/api/agents/abc")
        XCTAssertEqual(HostEndpoint(string: "https://h.example")?.webSocketURL?.absoluteString, "wss://h.example/ws")
    }

    func testPairingLink() throws {
        let link = try XCTUnwrap(PairingLink(string: "http://100.64.0.7:4317/#token=abc-DEF_123"))
        XCTAssertEqual(link.endpoint.displayString, "http://100.64.0.7:4317")
        XCTAssertEqual(link.token, "abc-DEF_123")
        XCTAssertEqual(link.string, "http://100.64.0.7:4317/#token=abc-DEF_123")
        XCTAssertEqual(PairingLink(host: "100.64.0.7", token: "abc")?.string, "http://100.64.0.7:4317/#token=abc")
        XCTAssertEqual(PairingLink(string: link.string), link)
        XCTAssertNil(PairingLink(string: "http://100.64.0.7:4317/"))
        XCTAssertNil(PairingLink(string: "http://100.64.0.7:4317/#token="))
        XCTAssertNil(PairingLink(string: "hello"))
        XCTAssertNil(PairingLink(host: "", token: "abc"))
    }

    func testEnvFile() {
        let values = EnvFile.parse("# comment\nSWITCHBOARD_TOKEN=abc=def\n SWITCHBOARD_PORT = \"5000\" \n\nBROKEN\n")
        XCTAssertEqual(values, ["SWITCHBOARD_TOKEN": "abc=def", "SWITCHBOARD_PORT": "5000"])
        XCTAssertNil(EnvFile.token(inFolder: "/nonexistent/folder"))
    }

    func testCountdownAndRelativeTime() {
        XCTAssertEqual(Countdown.clock(remaining: 600), "10:00")
        XCTAssertEqual(Countdown.clock(remaining: 59.2), "1:00")
        XCTAssertEqual(Countdown.clock(remaining: 5), "0:05")
        XCTAssertEqual(Countdown.clock(remaining: -3), "0:00")
        XCTAssertEqual(Countdown.spoken(remaining: 65), "1 min 5 s left")
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(RelativeTime.short(from: now.addingTimeInterval(-20), now: now), "just now")
        XCTAssertEqual(RelativeTime.short(from: now.addingTimeInterval(-150), now: now), "2 min ago")
        XCTAssertEqual(RelativeTime.short(from: now.addingTimeInterval(-7300), now: now), "2 h ago")
        XCTAssertEqual(RelativeTime.short(from: now.addingTimeInterval(-200_000), now: now), "2 d ago")
        XCTAssertEqual(RelativeTime.short(from: now.addingTimeInterval(30), now: now), "just now")
    }

    func testBackoff() {
        XCTAssertEqual((1...7).map(Backoff.delay(attempt:)), [0.5, 1, 2, 4, 8, 8, 8])
        XCTAssertEqual(Backoff.delay(attempt: 500), 8)
    }

    func testTranscriptAccumulator() {
        var accumulator = TranscriptAccumulator()
        accumulator.update("Run the")
        accumulator.update("Run the tests now")
        XCTAssertEqual(accumulator.text, "Run the tests now")
        accumulator.update("and")
        accumulator.update("and fix them")
        XCTAssertEqual(accumulator.text, "Run the tests now and fix them")
        XCTAssertEqual(SpeechRecognizer.merge(base: "Hello", transcript: "world"), "Hello world")
        XCTAssertEqual(SpeechRecognizer.merge(base: "", transcript: "world"), "world")
        XCTAssertEqual(SpeechRecognizer.merge(base: "Line\n", transcript: "next"), "Line\nnext")
    }

    func testTextChunksCutAtLineEndsAndKeepEverything() {
        XCTAssertEqual(TextChunks.split("short", limit: 10), ["short"])
        XCTAssertEqual(TextChunks.split("", limit: 10), [""])
        XCTAssertEqual(TextChunks.split("one\ntwo\nthree\nfour", limit: 9), ["one\ntwo", "three", "four"])
        XCTAssertEqual(TextChunks.split("abcdefghij", limit: 4), ["abcd", "efgh", "ij"])
        let long = (0..<5000).map { "line \($0)" }.joined(separator: "\n")
        let chunks = TextChunks.split(long, limit: 12_000)
        XCTAssertGreaterThan(chunks.count, 1)
        XCTAssertEqual(chunks.joined(separator: "\n"), long)
    }

    func testAgentIdentity() {
        XCTAssertEqual(AgentIdentity.monogram(for: "maya"), "M")
        XCTAssertEqual(AgentIdentity.monogram(for: "deploy check-bot"), "DC")
        XCTAssertEqual(AgentIdentity.monogram(for: "  "), "?")
        XCTAssertEqual(AgentIdentity.hue(for: "abc"), AgentIdentity.hue(for: "abc"))
        XCTAssertNotEqual(AgentIdentity.hue(for: "abc"), AgentIdentity.hue(for: "abd"))
        XCTAssertTrue((0..<1).contains(AgentIdentity.hue(for: "11111111-1111-4111-8111-111111111111")))
    }

    func testJSONValuePrettyPrinting() {
        let value = JSONValue.object(["b": .number(2), "a": .array([.bool(true), .null, .string("x/y")])])
        XCTAssertEqual(value.prettyPrinted, "{\n  \"a\" : [\n    true,\n    null,\n    \"x/y\"\n  ],\n  \"b\" : 2\n}")
    }
}
