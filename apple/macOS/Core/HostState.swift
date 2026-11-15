import Foundation

enum HostState: Hashable, Sendable {
    case unknown
    case stopped
    case starting
    case running
    case stopping
    case failed(String)

    var label: String {
        switch self {
        case .unknown: "Checking the host"
        case .stopped: "Host stopped"
        case .starting: "Host starting"
        case .running: "Host running"
        case .stopping: "Host stopping"
        case .failed: "Host failed to start"
        }
    }
}
