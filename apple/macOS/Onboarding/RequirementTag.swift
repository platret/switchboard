import SwiftUI

struct RequirementTag: View {
    let isRequired: Bool

    var body: some View {
        Text(isRequired ? "Required" : "Optional")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(isRequired ? Palette.cobalt : Color.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isRequired ? Palette.cobalt.opacity(0.12) : Color.primary.opacity(0.06), in: Capsule())
            .accessibilityHidden(true)
    }
}
