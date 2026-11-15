import Foundation

struct PairingLink: Hashable, Sendable {
    let endpoint: HostEndpoint
    let token: String

    init(endpoint: HostEndpoint, token: String) {
        self.endpoint = endpoint
        self.token = token
    }

    init?(host: String, port: Int = HostEndpoint.defaultPort, token: String) {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty, !trimmed.contains("://"), let endpoint = HostEndpoint(string: "http://\(trimmed):\(port)") else { return nil }
        self.init(endpoint: endpoint, token: token)
    }

    init?(string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed), let fragment = components.percentEncodedFragment else { return nil }
        guard let token = PairingLink.token(inFragment: fragment), let endpoint = HostEndpoint(string: trimmed) else { return nil }
        self.init(endpoint: endpoint, token: token)
    }

    var url: URL? {
        guard var components = URLComponents(url: endpoint.baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/"
        components.percentEncodedFragment = "token=\(token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? token)"
        return components.url
    }

    var string: String {
        url?.absoluteString ?? ""
    }

    private static func token(inFragment fragment: String) -> String? {
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2, parts[0] == "token", let token = parts[1].removingPercentEncoding, !token.isEmpty else { continue }
            return token
        }
        return nil
    }
}
