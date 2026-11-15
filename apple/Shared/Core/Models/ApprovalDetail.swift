import Foundation

enum ApprovalDetail: Hashable, Sendable {
    case command(String, runsInBackground: Bool)
    case edit(path: String, removed: String, added: String, replacesAll: Bool)
    case write(path: String, content: String)
    case other(json: String)
}

extension Approval {
    private static let actions: [String: String] = [
        "Bash": "run a command",
        "Edit": "edit a file",
        "Write": "write a file",
        "NotebookEdit": "edit a notebook",
        "WebFetch": "fetch a web page",
        "WebSearch": "search the web",
        "Read": "read a file outside the project",
        "Glob": "list files outside the project",
        "Grep": "search files outside the project",
    ]

    var action: String {
        Approval.actions[toolName] ?? "use \(toolName)"
    }

    var isSummaryComplete: Bool {
        if case .command(let command, _) = detail { return command.split(whereSeparator: \.isWhitespace).joined(separator: " ") == summary }
        return false
    }

    var detail: ApprovalDetail {
        if toolName == "Bash", let command = input.string("command") {
            return .command(command, runsInBackground: input.flag("run_in_background"))
        }
        if toolName == "Edit", let path = input.string("file_path"), let removed = input.string("old_string"), let added = input.string("new_string") {
            return .edit(path: path, removed: removed, added: added, replacesAll: input.flag("replace_all"))
        }
        if toolName == "Write", let path = input.string("file_path"), let content = input.string("content") {
            return .write(path: path, content: content)
        }
        return .other(json: input.prettyPrinted)
    }
}
