import SwiftUI

struct OnboardingView: View {
    static let size = CGSize(width: 760, height: 540)
    static let cardWidth: CGFloat = 520

    let model: OnboardingModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: model.step)
                .padding(.top, 22)
            ZStack {
                content
                    .id(model.step)
                    .transition(.onboardingStep(forward: model.isForward, reduceMotion: reduceMotion))
            }
            .padding(.horizontal, 56)
            .padding(.top, 26)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            OnboardingFooter(model: model)
                .padding(.horizontal, 56)
                .padding(.bottom, 22)
        }
        .frame(width: OnboardingView.size.width, height: OnboardingView.size.height)
        .background(OnboardingBackground())
        .animation(OnboardingMotion.step(reduceMotion: reduceMotion), value: model.step)
        .onExitCommand {}
    }

    @ViewBuilder private var content: some View {
        switch model.step {
        case .welcome: WelcomeStep()
        case .checks: ChecksStep(checks: model.checks)
        case .projects: ProjectsStep(editor: model.projects)
        case .host: HostStep(host: model.host)
        case .phone: PhoneStep(model: model)
        case .done: DoneStep()
        }
    }
}
