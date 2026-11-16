import Foundation

/// Agents use the Claude Code login only: the host strips ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN
/// from their environment, so an API key in the app's environment does not count as signed in.
enum ClaudeAccount {
    static let configName = ".claude.json"
    static let accountKey = "oauthAccount"

    static func isSignedIn(config: Data?) -> Bool {
        guard let config, let object = try? JSONSerialization.jsonObject(with: config) as? [String: Any] else { return false }
        guard let account = object[accountKey] else { return false }
        return !(account is NSNull)
    }

    static func isSignedIn(home: URL) -> Bool {
        isSignedIn(config: try? Data(contentsOf: home.appending(path: configName)))
    }
}
