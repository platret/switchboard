import Foundation

enum RuntimeStatus: Hashable, Sendable {
    case bundled
    case repo(RepoToolchain)
    case missing
}
