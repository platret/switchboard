import Foundation

struct HostEndpoint: Hashable, Sendable {
    static let defaultPort = 4317
    static let localhost = "http://127.0.0.1:4317"

    let baseURL: URL

    init?(string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let hasScheme = trimmed.contains("://")
        guard var components = URLComponents(string: hasScheme ? trimmed : "http://\(trimmed)") else { return nil }
        guard let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return nil }
        guard let host = components.host, !host.isEmpty else { return nil }
        if !hasScheme, components.port == nil { components.port = HostEndpoint.defaultPort }
        components.scheme = scheme
        components.path = ""
        components.query = nil
        components.fragment = nil
        components.user = nil
        components.password = nil
        guard let url = components.url else { return nil }
        baseURL = url
    }

    var isLocal: Bool {
        ["127.0.0.1", "localhost", "::1"].contains(baseURL.host() ?? "")
    }

    var displayString: String {
        baseURL.absoluteString
    }

    var webSocketURL: URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/ws"
        return components.url
    }

    func apiURL(_ path: String) -> URL {
        baseURL.appending(path: "api").appending(path: path)
    }
}
