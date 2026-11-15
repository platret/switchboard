import Foundation

@MainActor
protocol NotificationPosting: AnyObject {
    func postApproval(_ approval: Approval, agentName: String)
    func postFinished(_ agent: Agent)
    func withdrawApproval(id: String)
    func withdrawApprovals(except pending: Set<String>)
    func setBadge(_ count: Int)
}
