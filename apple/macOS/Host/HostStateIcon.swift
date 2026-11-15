import SwiftUI

struct HostStateIcon: View {
    let state: HostState

    var body: some View {
        switch state {
        case .running:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).accessibilityHidden(true)
        case .stopped:
            Image(systemName: "stop.circle").foregroundStyle(.secondary).accessibilityHidden(true)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.danger).accessibilityHidden(true)
        case .unknown, .starting, .stopping:
            ProgressView().controlSize(.small).accessibilityHidden(true)
        }
    }
}
