import SwiftUI

struct WelcomeFeatureLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 7) {
            configuration.icon.foregroundStyle(Palette.cobalt)
            configuration.title
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Palette.cobalt.opacity(0.08), in: Capsule())
    }
}
