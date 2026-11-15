import Foundation

struct DictationLanguage: Identifiable, Hashable {
    let id: String
    let name: String

    static func all(including selected: String) -> [DictationLanguage] {
        var identifiers = Set(SpeechRecognizer.supportedLocales.map(\.identifier))
        if !selected.isEmpty { identifiers.insert(selected) }
        return identifiers
            .map { DictationLanguage(id: $0, name: Locale.current.localizedString(forIdentifier: $0) ?? $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
