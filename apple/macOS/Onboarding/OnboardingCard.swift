import AppKit
import SwiftUI

struct OnboardingCard: ViewModifier {
    var corner: CGFloat = 12

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .background(Color(nsColor: .controlBackgroundColor), in: shape)
            .overlay(shape.strokeBorder(Surface.hairline, lineWidth: 1))
    }
}

extension View {
    func onboardingCard(corner: CGFloat = 12) -> some View {
        modifier(OnboardingCard(corner: corner))
    }
}
