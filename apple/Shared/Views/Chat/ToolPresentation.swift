import Foundation

enum ToolPresentation {
    private static let symbols: [String: String] = [
        "Bash": "terminal",
        "Read": "doc.text",
        "Edit": "pencil.line",
        "Write": "square.and.pencil",
        "NotebookEdit": "book",
        "Glob": "folder",
        "Grep": "magnifyingglass",
        "ToolSearch": "magnifyingglass",
        "WebFetch": "globe",
        "WebSearch": "globe",
        "Agent": "person.2",
        "Task": "person.2",
        "TodoWrite": "checklist",
        "Skill": "sparkles",
    ]

    static func symbol(for name: String) -> String {
        if let symbol = symbols[name] { return symbol }
        return name.hasPrefix("mcp__") ? "puzzlepiece.extension" : "wrench.and.screwdriver"
    }

    static func title(for name: String) -> String {
        guard name.hasPrefix("mcp__"), let tool = name.components(separatedBy: "__").last, !tool.isEmpty else { return name }
        return tool.replacingOccurrences(of: "_", with: " ")
    }

    static func label(for status: ToolStatus) -> String {
        switch status {
        case .running: "Running"
        case .done: "Done"
        case .error: "Failed"
        case .denied: "Denied"
        }
    }

    static func overall(_ calls: [ToolCall]) -> ToolStatus {
        let statuses = Set(calls.map(\.status))
        return [ToolStatus.running, .denied, .error].first { statuses.contains($0) } ?? .done
    }

    static func detail(for call: ToolCall) -> ApprovalDetail {
        Approval(id: call.toolUseId, agentId: "", toolName: call.name, input: call.input).detail
    }
}
