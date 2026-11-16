import SwiftUI

struct OnboardingHeader: View {
    let title: String
    let subtitle: String
    var revealIndex = 0

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 26, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 470)
        }
        .reveal(revealIndex)
    }
}
