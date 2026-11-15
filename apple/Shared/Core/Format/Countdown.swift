import Foundation

enum Countdown {
    static func clock(remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded(.up)))
        let padded = seconds % 60 < 10 ? "0\(seconds % 60)" : "\(seconds % 60)"
        return "\(seconds / 60):\(padded)"
    }

    static func spoken(remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded(.up)))
        let minutes = seconds / 60
        if minutes == 0 { return "\(seconds) seconds left" }
        return "\(minutes) min \(seconds % 60) s left"
    }
}
