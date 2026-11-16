import Foundation

struct SystemProbe: Sendable {
    var home = FileManager.default.homeDirectoryForCurrentUser
    var bundled: BundledHost?

    func gather(source: HostSourceKind?, toolchain: RepoToolchain?) -> SystemSnapshot {
        var snapshot = SystemSnapshot()
        switch source {
        case .bundled?: snapshot.runtime = .bundled
        case .repo?: snapshot.runtime = .repo(toolchain ?? RepoToolchain.find())
        case nil: snapshot.runtime = .missing
        }
        snapshot.isClaudeSignedIn = ClaudeAccount.isSignedIn(home: home)
        snapshot.claudePath = ClaudeCLI.locate(home: home, bundled: bundled)
        snapshot.claudeApp = AppPresence.find(bundleIdentifiers: KnownApp.claudeIdentifiers)
        snapshot.tailscale = AppPresence.find(bundleIdentifiers: KnownApp.tailscaleIdentifiers, paths: KnownApp.tailscalePaths)
        snapshot.tailscaleAddress = TailscaleAddress.find()
        return snapshot
    }
}
