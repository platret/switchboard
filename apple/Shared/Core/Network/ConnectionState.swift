import Foundation

enum ConnectionState: Hashable, Sendable {
    case notConfigured
    case connecting
    case connected
    case reconnecting
    case tokenRejected

    var label: String {
        switch self {
        case .notConfigured: "Not set up"
        case .connecting: "Connecting"
        case .connected: "Connected"
        case .reconnecting: "Reconnecting"
        case .tokenRejected: "Token rejected"
        }
    }
}
