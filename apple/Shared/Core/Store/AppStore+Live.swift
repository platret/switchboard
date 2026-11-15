import Foundation

extension AppStore {
    static func live() -> AppStore {
        let notifications = NotificationService()
        let store = AppStore(tokens: KeychainTokenStore(), notifications: notifications)
        notifications.onDecision = { [weak store] approvalId, decision in
            store?.answerFromNotification(approvalId: approvalId, decision: decision)
        }
        notifications.onOpenAgent = { [weak store] agentId in
            store?.openAgent(id: agentId)
        }
        notifications.activate()
        return store
    }

    var notificationService: NotificationService? {
        notifications as? NotificationService
    }
}
