import Foundation

enum ChatRole: String, LenientEnum, Sendable {
    case user
    case assistant
    case system

    static let fallback = ChatRole.system
}
