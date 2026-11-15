import Foundation
import UserNotifications

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Task { @MainActor in
            completionHandler(AppActivity.isActive() ? [] : [.banner, .list, .sound])
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let info = response.notification.request.content.userInfo
        let approvalId = info[Identifier.approvalId] as? String
        let agentId = info[Identifier.agentId] as? String
        Task { @MainActor in
            self.route(action: action, approvalId: approvalId, agentId: agentId)
            if approvalId != nil, action != UNNotificationDefaultActionIdentifier { try? await Task.sleep(for: .seconds(3)) }
            completionHandler()
        }
    }
}
