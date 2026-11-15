import Foundation

enum Fixtures {
    static let bootstrap = """
    {"type":"bootstrap","bootstrap":{"projects":[{"id":"work","name":"Work","path":"/Users/me/code/app","additionalDirectories":["/Users/me/code/shared-lib"],"agents":["tutor","reviewer","dev","tester"]},{"id":"side","name":"Side project","path":"/Users/me/code/sideproject","additionalDirectories":[],"agents":["ideation","dev"]}],"roles":[{"id":"dev","name":"Developer","description":"Builds features and fixes bugs.","systemPrompt":"You are a developer agent in Switchboard.","tools":["Read","Glob","Grep","Edit","Write","Bash"],"starters":["What is the state of this project? Give me a short tour.","Run the checks and fix what fails."]},{"id":"ideation","name":"Ideation","systemPrompt":"You think.","tools":["Read"],"model":"claude-opus-4-5"}],"agents":[{"id":"11111111-1111-4111-8111-111111111111","name":"Maya","projectId":"side","role":"ideation","sessionId":"33333333-3333-4333-8333-333333333333","status":"idle","createdAt":1794702904877,"lastActivityAt":1794702918154,"preview":"Hello from the fixture.","activity":null,"queue":[],"trustedTools":[]},{"id":"22222222-2222-4222-8222-222222222222","name":"Nora","projectId":"side","role":"dev","sessionId":null,"status":"working","createdAt":1794703283071,"lastActivityAt":1794703283999,"preview":null,"activity":"Bash: pnpm test","queue":[{"id":"q1","text":"then run the linter"}],"trustedTools":["Edit"]}],"approvals":[{"id":"ap1","agentId":"22222222-2222-4222-8222-222222222222","toolName":"Bash","summary":"pnpm test","input":{"command":"pnpm test","run_in_background":true},"createdAt":1794703290000,"expiresAt":1794703890000}],"host":{"tailscaleUrl":"http://100.64.0.7:4317"}}}
    """

    static let textItem = """
    {"type":"chat.item","item":{"id":"3a91ccf5","agentId":"a1","role":"user","content":{"kind":"text","text":"hi there"},"createdAt":1794702910760}}
    """

    static let toolItem = """
    {"type":"chat.item","item":{"id":"t1","agentId":"a1","role":"assistant","content":{"kind":"tool","toolUseId":"toolu_01","name":"Edit","summary":"src/app.ts","input":{"file_path":"/repo/src/app.ts","old_string":"a","new_string":"b","replace_all":false,"nested":{"list":[1,2.5,null,"x"]}},"status":"running"},"createdAt":1794702911000}}
    """

    static let finishedToolItem = """
    {"type":"chat.item","item":{"id":"t1","agentId":"a1","role":"assistant","content":{"kind":"tool","toolUseId":"toolu_01","name":"Edit","summary":"src/app.ts","input":{"file_path":"/repo/src/app.ts"},"status":"done","result":"The file was updated."},"createdAt":1794702911000}}
    """

    static let futureItem = """
    {"type":"chat.item","item":{"id":"f1","agentId":"a1","role":"narrator","content":{"kind":"image","url":"http://example.test/a.png"},"createdAt":1794702912000}}
    """

    static let history = """
    {"type":"history","agentId":"a1","history":{"items":[{"id":"i1","agentId":"a1","role":"user","content":{"kind":"text","text":"hello"},"createdAt":1794702910760},{"id":"broken","agentId":"a1","role":"assistant","content":{"kind":"tool"},"createdAt":1794702910761},{"id":"i2","agentId":"a1","role":"system","content":{"kind":"notice","text":"Stopped"},"createdAt":1794702910762},{"id":"i3","agentId":"a1","role":"system","content":{"kind":"error","text":"Claude reported: overloaded"},"createdAt":1794702910763}],"drafts":[{"id":"d1","text":"Thinking about"}]}}
    """

    static let approvalRequested = """
    {"type":"approval.requested","approval":{"id":"ap2","agentId":"a1","toolName":"Write","summary":"notes.md","input":{"file_path":"/repo/notes.md","content":"# Notes"},"createdAt":1794703290000,"expiresAt":1794703890000}}
    """

    static let approvalResolved = """
    {"type":"approval.resolved","approvalId":"ap2","agentId":"a1","decision":"deny","by":"timeout"}
    """

    static func agent(id: String = "a1", project: String = "side", status: AgentStatus = .idle, lastActivity: TimeInterval = 0, created: TimeInterval = 0) -> Agent {
        Agent(id: id, name: id, projectId: project, role: "dev", status: status, createdAt: Date(timeIntervalSince1970: created), lastActivityAt: Date(timeIntervalSince1970: lastActivity))
    }

    static func message(_ json: String, file: StaticString = #filePath, line: UInt = #line) throws -> ServerMessage {
        try JSONCoding.decode(ServerMessage.self, from: json)
    }

    @MainActor
    static func store() -> AppStore {
        let suite = "switchboard.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return AppStore(settings: AppSettings(defaults: defaults), tokens: InMemoryTokenStore())
    }
}
