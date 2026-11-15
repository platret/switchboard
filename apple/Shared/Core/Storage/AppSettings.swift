import Foundation
import Observation

@Observable
final class AppSettings {
    private enum Key {
        static let hostURL = "hostURL"
        static let repoFolder = "repoFolder"
        static let lastProjectId = "lastProjectId"
        static let startsHostOnLaunch = "startsHostOnLaunch"
        static let dictationLocale = "dictationLocale"
        static let notifiesWhenFinished = "notifiesWhenFinished"
        static let hostProcessGroup = "hostProcessGroup"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var hostURL: String { didSet { defaults.set(hostURL, forKey: Key.hostURL) } }
    var repoFolder: String { didSet { defaults.set(repoFolder, forKey: Key.repoFolder) } }
    var lastProjectId: String? { didSet { defaults.set(lastProjectId, forKey: Key.lastProjectId) } }
    var startsHostOnLaunch: Bool { didSet { defaults.set(startsHostOnLaunch, forKey: Key.startsHostOnLaunch) } }
    var dictationLocale: String { didSet { defaults.set(dictationLocale, forKey: Key.dictationLocale) } }
    var notifiesWhenFinished: Bool { didSet { defaults.set(notifiesWhenFinished, forKey: Key.notifiesWhenFinished) } }
    @ObservationIgnored var hostProcessGroup: Int32? { didSet { defaults.set(hostProcessGroup, forKey: Key.hostProcessGroup) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hostURL = defaults.string(forKey: Key.hostURL) ?? AppSettings.defaultHostURL
        repoFolder = defaults.string(forKey: Key.repoFolder) ?? ""
        lastProjectId = defaults.string(forKey: Key.lastProjectId)
        startsHostOnLaunch = defaults.object(forKey: Key.startsHostOnLaunch) as? Bool ?? true
        dictationLocale = defaults.string(forKey: Key.dictationLocale) ?? ""
        notifiesWhenFinished = defaults.object(forKey: Key.notifiesWhenFinished) as? Bool ?? true
        hostProcessGroup = (defaults.object(forKey: Key.hostProcessGroup) as? Int).map(Int32.init(clamping:))
    }

    var endpoint: HostEndpoint? {
        HostEndpoint(string: hostURL)
    }

    private static var defaultHostURL: String {
        #if os(macOS)
        HostEndpoint.localhost
        #else
        ""
        #endif
    }
}
