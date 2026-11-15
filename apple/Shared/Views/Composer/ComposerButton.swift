import SwiftUI

struct ComposerButton: View {
    let symbol: String
    let label: String
    var fill: Color?
    var isEnabled = true
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 32

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(fill == nil ? Color.secondary : Surface.onAccent(colorScheme))
                .frame(width: side, height: side)
                .background(fill ?? .clear, in: Circle())
                .padding(3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .accessibilityLabel(label)
        .help(label)
    }
}
