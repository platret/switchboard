import SwiftUI

@main
struct SwitchboardApp: App {
    @State private var store = AppStore.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task { store.start() }
        }
    }
}
