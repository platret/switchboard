import SwiftUI

struct StepShift: ViewModifier {
    var offset: CGFloat = 0
    var blur: CGFloat = 0
    var opacity: Double = 1

    func body(content: Content) -> some View {
        content.offset(x: offset).blur(radius: blur).opacity(opacity)
    }
}

extension AnyTransition {
    static func onboardingStep(forward: Bool, reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let distance: CGFloat = forward ? 44 : -44
        return .asymmetric(
            insertion: .modifier(active: StepShift(offset: distance, opacity: 0), identity: StepShift()),
            removal: .modifier(active: StepShift(blur: 6, opacity: 0), identity: StepShift()).combined(with: .scale(scale: 0.985))
        )
    }
}
