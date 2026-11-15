import SwiftUI

struct HoverRow<Content: View>: View {
    var isSelected = false
    let action: () -> Void
    @ViewBuilder let content: Content

    @State private var isHovered = false

    private var fill: Color {
        if isSelected { return Color.primary.opacity(0.12) }
        return isHovered ? Color.primary.opacity(0.06) : .clear
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fill, in: RoundedRectangle(cornerRadius: Surface.corner, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
