import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.needsSetup {
                OnboardingScreen()
            } else {
                MainView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.needsSetup)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshConnection() }
        }
        .task(id: store.isReady) {
            guard store.isReady, await NotificationPermission.current() == .notAsked else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await store.notificationService?.requestAuthorization()
        }
    }
}
