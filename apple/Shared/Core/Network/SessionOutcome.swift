import Foundation

enum SessionOutcome: Hashable, Sendable {
    case rejected
    case dropped
    case failed
}
