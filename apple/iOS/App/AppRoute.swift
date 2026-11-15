import Foundation

enum AppRoute: Hashable {
    case agent(String)
    case overview
    case settings

    var agentId: String? {
        if case .agent(let id) = self { return id }
        return nil
    }
}
