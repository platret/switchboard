import SwiftUI

struct Reveal: ViewModifier {
    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.revealsInstantly) private var revealsInstantly
    @State private var isShown = false

    private var visible: Bool {
        isShown || revealsInstantly
    }

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 10)
            .onAppear {
                let animation = reduceMotion ? OnboardingMotion.fade : OnboardingMotion.settle
                withAnimation(animation.delay(Double(index) * OnboardingMotion.stagger + 0.08)) { isShown = true }
            }
    }
}

extension View {
    func reveal(_ index: Int) -> some View {
        modifier(Reveal(index: index))
    }
}
