import SwiftUI

struct RoleChip: View {
    let role: Role
    let isSelected: Bool
    var isEditable = true
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                }
                Text(role.name)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isSelected ? Palette.cobalt : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(isSelected ? Palette.cobalt.opacity(0.14) : Color.primary.opacity(0.06), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEditable)
        .help(role.description)
        .animation(OnboardingMotion.settle, value: isSelected)
        .accessibilityLabel(role.name)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
