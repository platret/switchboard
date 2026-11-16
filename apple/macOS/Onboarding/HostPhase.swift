import Foundation

enum HostPhase: Hashable {
    case idle
    case working
    case running(owned: Bool)
    case failed(String)

    init(_ state: HostState, ownsProcess: Bool) {
        switch state {
        case .stopped: self = .idle
        case .unknown, .starting, .stopping: self = .working
        case .running: self = .running(owned: ownsProcess)
        case .failed(let message): self = .failed(message)
        }
    }
}
