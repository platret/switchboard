import Foundation

struct SystemSnapshot: Hashable, Sendable {
    var runtime: RuntimeStatus = .missing
    var isHostRunning = false
    var port = HostEndpoint.defaultPort
    var isClaudeSignedIn = false
    var claudePath: String?
    var claudeApp = AppPresence()
    var tailscale = AppPresence()
    var tailscaleAddress: String?
    var notifications: NotificationAccess = .unknown
}
