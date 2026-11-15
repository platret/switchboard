import Foundation

enum AgentStatus: String, LenientEnum, CaseIterable, Sendable {
    case idle
    case working
    case waiting
    case error

    static let fallback = AgentStatus.idle

    var isBusy: Bool {
        self == .working || self == .waiting
    }

    var urgency: Int {
        switch self {
        case .waiting: 0
        case .error: 1
        case .working: 2
        case .idle: 3
        }
    }

    var label: String {
        switch self {
        case .idle: "Idle"
        case .working: "Working"
        case .waiting: "Needs approval"
        case .error: "Error"
        }
    }
}
