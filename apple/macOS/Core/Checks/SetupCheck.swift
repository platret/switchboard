import Foundation

struct SetupCheck: Identifiable, Hashable, Sendable {
    enum Kind: String, CaseIterable, Sendable {
        case host
        case claude
        case claudeApp
        case tailscale
        case notifications
    }

    let kind: Kind
    var level: CheckLevel
    var detail: String
    var action: CheckAction?

    var id: Kind {
        kind
    }

    var isRequired: Bool {
        kind == .host || kind == .claude
    }

    var title: String {
        switch kind {
        case .host: "Switchboard host"
        case .claude: "Claude Code sign-in"
        case .claudeApp: "Claude app"
        case .tailscale: "Tailscale"
        case .notifications: "Notifications"
        }
    }
}
