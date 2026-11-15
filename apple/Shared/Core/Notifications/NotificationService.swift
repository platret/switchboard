import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, NotificationPosting {
    enum Identifier {
        static let approvalCategory = "switchboard.approval"
        static let finishedCategory = "switchboard.finished"
        static let allow = "switchboard.approval.allow"
        static let deny = "switchboard.approval.deny"
        static let approvalId = "approvalId"
        static let agentId = "agentId"
    }

    var onDecision: ((String, ApprovalDecision) -> Void)?
    var onOpenAgent: ((String) -> Void)?

    private var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    func activate() {
        let allow = UNNotificationAction(identifier: Identifier.allow, title: "Allow", options: [.authenticationRequired])
        let deny = UNNotificationAction(identifier: Identifier.deny, title: "Deny", options: [.destructive])
        let approval = UNNotificationCategory(identifier: Identifier.approvalCategory, actions: [allow, deny], intentIdentifiers: [])
        let finished = UNNotificationCategory(identifier: Identifier.finishedCategory, actions: [], intentIdentifiers: [])
        center.delegate = self
        center.setNotificationCategories([approval, finished])
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }

    func postApproval(_ approval: Approval, agentName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(agentName) wants to \(approval.action)"
        content.body = approval.summary
        content.sound = .default
        content.categoryIdentifier = Identifier.approvalCategory
        content.threadIdentifier = approval.agentId
        content.userInfo = [Identifier.approvalId: approval.id, Identifier.agentId: approval.agentId]
        post(content, id: NotificationService.requestId(approvalId: approval.id))
    }

    func postFinished(_ agent: Agent) {
        let content = UNMutableNotificationContent()
        content.title = agent.status == .error ? "\(agent.name) ran into an error" : "\(agent.name) finished"
        content.body = agent.preview ?? ""
        content.sound = .default
        content.categoryIdentifier = Identifier.finishedCategory
        content.threadIdentifier = agent.id
        content.userInfo = [Identifier.agentId: agent.id]
        post(content, id: "finished-\(agent.id)")
    }

    func withdrawApproval(id: String) {
        let ids = [NotificationService.requestId(approvalId: id)]
        center.removeDeliveredNotifications(withIdentifiers: ids)
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func withdrawApprovals(except pending: Set<String>) {
        let center = center
        Task {
            let delivered = await center.deliveredNotifications().map(\.request)
            let approvals = delivered.filter { $0.content.categoryIdentifier == Identifier.approvalCategory }
            let stale = approvals.filter { request in
                guard let approvalId = request.content.userInfo[Identifier.approvalId] as? String else { return true }
                return !pending.contains(approvalId)
            }
            center.removeDeliveredNotifications(withIdentifiers: stale.map(\.identifier))
        }
    }

    func setBadge(_ count: Int) {
        center.setBadgeCount(count) { _ in }
    }

    func route(action: String, approvalId: String?, agentId: String?) {
        switch action {
        case Identifier.allow:
            if let approvalId { onDecision?(approvalId, .allow) }
        case Identifier.deny:
            if let approvalId { onDecision?(approvalId, .deny) }
        case UNNotificationDefaultActionIdentifier:
            if let agentId { onOpenAgent?(agentId) }
        default:
            break
        }
    }

    private func post(_ content: UNNotificationContent, id: String) {
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil)) { _ in }
    }

    private static func requestId(approvalId: String) -> String {
        "approval-\(approvalId)"
    }
}
