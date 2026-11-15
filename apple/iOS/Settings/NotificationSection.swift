import SwiftUI
import UIKit

struct NotificationSection: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var permission: NotificationPermission?

    var body: some View {
        @Bindable var settings = store.settings
        Section {
            LabeledContent("Notifications", value: permission?.label ?? "Checking")
            if permission == .notAsked {
                Button("Allow notifications", action: request)
            }
            if permission == .denied, let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                Button("Turn on in Settings") { openURL(url) }
            }
            Toggle("Tell me when an agent finishes", isOn: $settings.notifiesWhenFinished).tint(Palette.cobalt)
        } header: {
            SectionTitle("Notifications")
        } footer: {
            Text("Approvals always notify, with Allow and Deny right on the notification. There is no push server, so notifications arrive while Switchboard is open or was in the background only briefly.")
        }
        .task(id: scenePhase) {
            permission = await NotificationPermission.current()
        }
    }

    private func request() {
        Task {
            await store.notificationService?.requestAuthorization()
            permission = await NotificationPermission.current()
        }
    }
}
