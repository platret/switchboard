import SwiftUI

@main
struct SwitchboardMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var session = MacSession.shared

    var body: some Scene {
        Window("Switchboard", id: MacSession.mainWindowID) {
            MainWindow().session(session)
        }
        .defaultSize(width: 1160, height: 760)
        .commands {
            AppCommands(session: session)
        }

        Window("Set Up Switchboard", id: MacSession.onboardingWindowID) {
            OnboardingWindow().session(session)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra {
            MenuBarContent().session(session)
        } label: {
            MenuBarIcon().session(session)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().session(session)
        }
    }
}
