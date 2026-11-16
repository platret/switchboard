import Foundation

enum KnownApp {
    static let claudeIdentifiers = ["com.anthropic.claudefordesktop"]
    static let tailscaleIdentifiers = ["io.tailscale.ipn.macsys", "io.tailscale.ipn.macos"]
    static let tailscalePaths = ["/Applications/Tailscale.app"]
    static let terminalIdentifier = "com.apple.Terminal"

    static let claudeDownload = URL(string: "https://claude.ai/download")
    static let claudeCodeSetup = URL(string: "https://docs.claude.com/en/docs/claude-code/setup")
    static let tailscaleDownload = URL(string: "https://tailscale.com/download/mac")
    static let nodeDownload = URL(string: "https://nodejs.org/en/download")
    static let pnpmInstall = URL(string: "https://pnpm.io/installation")
    static let notificationSettings = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
}
