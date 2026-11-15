import UserNotifications

enum NotificationPermission: Equatable {
    case notAsked
    case allowed
    case denied

    var label: String {
        switch self {
        case .notAsked: "Not set up"
        case .allowed: "Allowed"
        case .denied: "Turned off"
        }
    }

    static func current() async -> NotificationPermission {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .notAsked
        case .denied: .denied
        default: .allowed
        }
    }
}
