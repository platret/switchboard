import SwiftUI

struct ActionButtonStyle: ButtonStyle {
    let kind: ActionButtonKind

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Surface.buttonCorner, style: .continuous)
    }

    private var foreground: Color {
        switch kind {
        case .primary: Surface.onAccent(colorScheme)
        case .secondary: Palette.cobalt
        case .destructive: Palette.danger
        }
    }

    private var background: Color {
        kind == .primary ? Palette.cobalt : Color.primary.opacity(0.08)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(kind == .primary ? .semibold : .regular)
            .foregroundStyle(foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, Surface.buttonInset)
            .background(background, in: shape)
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.65 : (isEnabled ? 1 : 0.4))
    }
}
