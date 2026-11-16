import Foundation

enum CheckAction: Hashable, Sendable {
    case signIn
    case getClaudeCode
    case getClaude
    case openClaude
    case getTailscale
    case openTailscale
    case allowNotifications
    case openNotificationSettings
    case getNode
    case getPnpm

    var title: String {
        switch self {
        case .signIn: "Sign in"
        case .getClaudeCode: "Get Claude Code"
        case .getClaude: "Get Claude"
        case .openClaude: "Open Claude"
        case .getTailscale: "Get Tailscale"
        case .openTailscale: "Open Tailscale"
        case .allowNotifications: "Allow"
        case .openNotificationSettings: "Open Settings"
        case .getNode: "Get Node"
        case .getPnpm: "Get pnpm"
        }
    }

    var link: URL? {
        switch self {
        case .getClaudeCode: KnownApp.claudeCodeSetup
        case .getClaude: KnownApp.claudeDownload
        case .getTailscale: KnownApp.tailscaleDownload
        case .openNotificationSettings: KnownApp.notificationSettings
        case .getNode: KnownApp.nodeDownload
        case .getPnpm: KnownApp.pnpmInstall
        case .signIn, .openClaude, .openTailscale, .allowNotifications: nil
        }
    }
}
