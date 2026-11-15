import Foundation

struct MessageListPin: Equatable {
    private static let grace: TimeInterval = 0.5

    private(set) var isPinned = true
    private var releasedAt = Date.distantPast

    var wasPinnedMomentsAgo: Bool {
        isPinned || Date().timeIntervalSince(releasedAt) < MessageListPin.grace
    }

    mutating func attach() {
        isPinned = true
    }

    mutating func release() {
        guard isPinned else { return }
        isPinned = false
        releasedAt = Date()
    }
}
