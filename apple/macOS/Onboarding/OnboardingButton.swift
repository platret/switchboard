import SwiftUI

struct OnboardingButton: View {
    let title: String
    var kind: ActionButtonKind = .primary
    var isDefault = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.vertical, 3)
                .frame(minWidth: kind == .primary ? 108 : nil)
        }
        .buttonStyle(ActionButtonStyle(kind: kind))
        .modifier(DefaultActionShortcut(isDefault: isDefault))
    }
}
