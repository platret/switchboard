import SwiftUI

struct OnboardingStepIndicator: View {
    let current: OnboardingStep

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                ZStack {
                    Capsule().fill(step < current ? Palette.cobalt.opacity(0.4) : Color.primary.opacity(0.14))
                    if step == current {
                        Capsule().fill(Palette.cobalt).matchedGeometryEffect(id: "current", in: namespace)
                    }
                }
                .frame(width: step == current ? 24 : 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current.rawValue + 1) of \(OnboardingStep.allCases.count), \(current.title)")
    }
}
