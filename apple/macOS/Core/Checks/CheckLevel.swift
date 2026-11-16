import Foundation

enum CheckLevel: Hashable, Sendable {
    case checking
    case ready
    case needed
    case optional

    var label: String {
        switch self {
        case .checking: "Checking"
        case .ready: "Ready"
        case .needed: "Needs attention"
        case .optional: "Not set up"
        }
    }
}
