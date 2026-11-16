import SwiftUI

struct GeneralSettings: View {
    @Environment(MacSession.self) private var session
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var settings = store.settings
        Form {
            Section {
                LaunchAtLoginToggle()
            } header: {
                SectionTitle("Startup")
            } footer: {
                Text("Switchboard keeps its menu bar item while the main window is closed.")
            }
            Section {
                Button("Set Up Switchboard…") { session.showOnboarding() }
            } header: {
                SectionTitle("Setup")
            } footer: {
                Text("Walk through the checks, projects and iPhone pairing again.")
            }
            NotificationSettings()
            Section {
                Picker("Language", selection: $settings.dictationLocale) {
                    Text("Same as the system").tag("")
                    ForEach(DictationLanguage.all) { language in
                        Text(language.name).tag(language.id)
                    }
                }
            } header: {
                SectionTitle("Dictation")
            } footer: {
                Text("The microphone button in the message field types what you say. Command D starts and stops it.")
            }
        }
        .formStyle(.grouped)
    }
}
