import Foundation

enum AgentNaming {
    static func suggestion(for role: Role, taken: [String]) -> String {
        let used = Set(taken.map { $0.lowercased() })
        guard used.contains(role.name.lowercased()) else { return role.name }
        let free = (2...99).first { !used.contains("\(role.name) \($0)".lowercased()) }
        return free.map { "\(role.name) \($0)" } ?? role.name
    }

    static func isValid(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= Agent.nameMaxLength
    }
}
