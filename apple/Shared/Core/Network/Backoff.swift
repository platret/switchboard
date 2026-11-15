import Foundation

enum Backoff {
    static let maximum: TimeInterval = 8

    static func delay(attempt: Int) -> TimeInterval {
        guard attempt > 1 else { return 0.5 }
        return min(maximum, 0.5 * pow(2, Double(min(attempt, 10) - 1)))
    }
}
