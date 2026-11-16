import SwiftUI

struct RevealsInstantlyKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var revealsInstantly: Bool {
        get { self[RevealsInstantlyKey.self] }
        set { self[RevealsInstantlyKey.self] = newValue }
    }
}
