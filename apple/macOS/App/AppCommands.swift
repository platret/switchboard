import SwiftUI

struct AppCommands: Commands {
    let session: MacSession

    @FocusedValue(\.agents) private var focused

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New agent") { session.newAgent() }.keyboardShortcut("n")
            Button("Quick switcher") { session.quickSwitch() }.keyboardShortcut("k")
            Divider()
            Button("Pair iPhone") { session.pairPhone() }
            Button("Open web app") { session.openWebApp() }
        }
        CommandMenu("Agent") {
            AgentMenu(session: session, focused: focused)
        }
    }
}
