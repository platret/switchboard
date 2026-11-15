import Foundation

enum RelativeTime {
    private static let steps: [(unit: String, seconds: TimeInterval)] = [("d", 86_400), ("h", 3_600), ("min", 60)]

    static func short(from date: Date, now: Date = Date()) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))
        for step in steps where elapsed >= step.seconds {
            return "\(Int(elapsed / step.seconds)) \(step.unit) ago"
        }
        return "just now"
    }

    static func spoken(from date: Date, now: Date = Date()) -> String {
        guard now.timeIntervalSince(date) >= 60 else { return "just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
