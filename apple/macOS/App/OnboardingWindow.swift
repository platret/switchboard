import SwiftUI

struct OnboardingWindow: View {
    @Environment(MacSession.self) private var session
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        OnboardingView(model: session.onboarding)
            .task { await session.onboarding.checks.watch() }
            .onAppear {
                session.onboarding.isPresented = true
                session.openMainWindow = { openWindow(id: MacSession.mainWindowID) }
                session.onboarding.onFinish = {
                    Task { await session.store.notificationService?.requestAuthorization() }
                    dismissWindow(id: MacSession.onboardingWindowID)
                    session.showMainWindow()
                }
            }
            .onDisappear { session.onboarding.isPresented = false }
    }
}
