import Foundation

enum ToolStatus: String, LenientEnum, Sendable {
    case running
    case done
    case error
    case denied

    static let fallback = ToolStatus.done
}
