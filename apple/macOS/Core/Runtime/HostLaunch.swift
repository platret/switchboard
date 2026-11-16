import Foundation

struct HostLaunch: Hashable, Sendable {
    let executable: URL
    let arguments: [String]
    let folder: String
    var environment: [String: String] = [:]
    let note: String
    let failure: String
}
