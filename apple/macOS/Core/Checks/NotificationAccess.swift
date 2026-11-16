import UserNotifications

enum NotificationAccess: Hashable, Sendable {
    case unknown
    case notDetermined
    case allowed
    case denied

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .provisional, .ephemeral: self = .allowed
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        @unknown default: self = .unknown
        }
    }

    static func current() async -> NotificationAccess {
        NotificationAccess(await UNUserNotificationCenter.current().notificationSettings().authorizationStatus)
    }
}
