import Foundation

enum ApprovalSource: String, LenientEnum, Sendable {
    case user
    case timeout
    case stop

    static let fallback = ApprovalSource.user
}
