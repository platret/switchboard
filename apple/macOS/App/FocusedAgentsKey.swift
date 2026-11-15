import SwiftUI

struct FocusedAgentsKey: FocusedValueKey {
    typealias Value = FocusedAgents
}

extension FocusedValues {
    var agents: FocusedAgents? {
        get { self[FocusedAgentsKey.self] }
        set { self[FocusedAgentsKey.self] = newValue }
    }
}
