import Foundation

struct DictationLanguage: Identifiable, Hashable {
    let id: String
    let name: String

    static let all: [DictationLanguage] = SpeechRecognizer.supportedLocales
        .map { DictationLanguage(id: $0.identifier, name: Locale.current.localizedString(forIdentifier: $0.identifier) ?? $0.identifier) }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
}
