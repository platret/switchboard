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
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hostSource = "hostSource"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var hostURL: String { didSet { defaults.set(hostURL, forKey: Key.hostURL) } }
    var repoFolder: String { didSet { defaults.set(repoFolder, forKey: Key.repoFolder) } }
    var lastProjectId: String? { didSet { defaults.set(lastProjectId, forKey: Key.lastProjectId) } }
    var startsHostOnLaunch: Bool { didSet { defaults.set(startsHostOnLaunch, forKey: Key.startsHostOnLaunch) } }
    var dictationLocale: String { didSet { defaults.set(dictationLocale, forKey: Key.dictationLocale) } }
    var notifiesWhenFinished: Bool { didSet { defaults.set(notifiesWhenFinished, forKey: Key.notifiesWhenFinished) } }
    var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) } }
    var hostSource: String? { didSet { defaults.set(hostSource, forKey: Key.hostSource) } }
    @ObservationIgnored var hostProcessGroup: Int32? { didSet { defaults.set(hostProcessGroup, forKey: Key.hostProcessGroup) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hostURL = defaults.string(forKey: Key.hostURL) ?? AppSettings.defaultHostURL
        repoFolder = defaults.string(forKey: Key.repoFolder) ?? ""
        lastProjectId = defaults.string(forKey: Key.lastProjectId)
        startsHostOnLaunch = defaults.object(forKey: Key.startsHostOnLaunch) as? Bool ?? true
        dictationLocale = defaults.string(forKey: Key.dictationLocale) ?? ""
        notifiesWhenFinished = defaults.object(forKey: Key.notifiesWhenFinished) as? Bool ?? true
        hasCompletedOnboarding = AppSettings.onboardingState(in: defaults, repoFolder: defaults.string(forKey: Key.repoFolder) ?? "")
        hostSource = defaults.string(forKey: Key.hostSource)
        hostProcessGroup = (defaults.object(forKey: Key.hostProcessGroup) as? Int).map(Int32.init(clamping:))
    }

    /// Someone who used Switchboard before onboarding existed already has a clone or a host saved,
    /// so they skip it. The answer is stored on first read, so a new user who quits halfway still sees it next time.
    private static func onboardingState(in defaults: UserDefaults, repoFolder: String) -> Bool {
        if let stored = defaults.object(forKey: Key.hasCompletedOnboarding) as? Bool { return stored }
        let isConfigured = !repoFolder.isEmpty || defaults.string(forKey: Key.hostURL) != nil
        defaults.set(isConfigured, forKey: Key.hasCompletedOnboarding)
        return isConfigured
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
