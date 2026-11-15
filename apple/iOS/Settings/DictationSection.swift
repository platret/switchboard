import SwiftUI

struct DictationSection: View {
    @Environment(AppStore.self) private var store
    @State private var languages: [DictationLanguage] = []

    var body: some View {
        @Bindable var settings = store.settings
        Section {
            Picker("Language", selection: $settings.dictationLocale) {
                Text("Same as this iPhone").tag("")
                ForEach(languages) { language in
                    Text(language.name).tag(language.id)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            SectionTitle("Dictation")
        } footer: {
            Text("The language the microphone button in the chat listens for.")
        }
        .task {
            if languages.isEmpty { languages = DictationLanguage.all(including: settings.dictationLocale) }
        }
    }
}
