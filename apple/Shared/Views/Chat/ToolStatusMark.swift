import SwiftUI

struct ToolStatusMark: View {
    let status: ToolStatus

    var body: some View {
        mark
            .font(.caption.weight(.semibold))
            .accessibilityElement()
            .accessibilityLabel(ToolPresentation.label(for: status))
    }

    @ViewBuilder private var mark: some View {
        switch status {
        case .running: StatusLamp(status: .working, size: 11)
        case .done: Image(systemName: "checkmark").foregroundStyle(.secondary)
        case .error: Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Palette.danger)
        case .denied: Image(systemName: "nosign").foregroundStyle(Palette.danger)
        }
    }
}
