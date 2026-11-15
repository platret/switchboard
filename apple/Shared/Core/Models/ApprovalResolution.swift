import Foundation

struct ApprovalResolution: Decodable, Hashable, Sendable {
    let approvalId: String
    let agentId: String
    let decision: ApprovalDecision
    let by: ApprovalSource
}
