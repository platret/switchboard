import AppKit
import SwiftUI

struct NotificationSettings: View {
    @Environment(AppStore.self) private var store
    @State private var isAuthorized: Bool?

    private static let systemPane = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")

    var body: some View {
        @Bindable var settings = store.settings
        Section {
            switch isAuthorized {
            case true?:
                Label("Notifications are on", systemImage: "checkmark.circle.fill")
            case false?:
                Label("Notifications are off for Switchboard", systemImage: "bell.slash")
                Button("Turn on notifications") {
                    Task { await enable() }
                }
            case nil:
                Label("Checking notifications", systemImage: "bell")
            }
            Toggle("Tell me when an agent finishes", isOn: $settings.notifiesWhenFinished)
        } header: {
            SectionTitle("Notifications")
        } footer: {
            Text("Approval requests notify you with Allow and Deny buttons whenever Switchboard is not in front.")
        }
        .task { await refresh() }
    }

    private func refresh() async {
        isAuthorized = await store.notificationService?.isAuthorized() ?? false
    }

    private func enable() async {
        let granted = await store.notificationService?.requestAuthorization() ?? false
        if !granted, let url = NotificationSettings.systemPane { NSWorkspace.shared.open(url) }
        await refresh()
    }
}
