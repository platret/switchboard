import Foundation

enum HostSource: Hashable, Sendable {
    case bundled(BundledHost, home: URL)
    case repo(folder: String)

    static let shell = URL(fileURLWithPath: "/bin/zsh")
    static let homeVariable = "SWITCHBOARD_HOME"
    static let repoCommand = "pnpm start"

    var kind: HostSourceKind {
        switch self {
        case .bundled: .bundled
        case .repo: .repo
        }
    }

    var envFolder: String {
        switch self {
        case .bundled(_, let home): home.path
        case .repo(let folder): folder
        }
    }

    var launch: HostLaunch {
        switch self {
        case .bundled(let host, let home):
            HostLaunch(executable: HostSource.shell, arguments: [host.start.path], folder: home.path, environment: [HostSource.homeVariable: home.path], note: "Starting the built-in host", failure: "Could not run the host inside Switchboard.")
        case .repo(let folder):
            HostLaunch(executable: HostSource.shell, arguments: ["-c", HostSource.repoCommand], folder: folder, note: "Starting the host in \(folder)", failure: "Could not run pnpm in \(folder).")
        }
    }

    var startingDetail: String {
        switch self {
        case .bundled: "Switchboard runs it from inside the app. This takes a few seconds."
        case .repo: "Running pnpm start. The first start builds the web app and can take a minute."
        }
    }

    var summary: String {
        switch self {
        case .bundled: "Switchboard runs the host it ships with and keeps its files in \(SwitchboardHome.displayPath(envFolder))."
        case .repo: "Switchboard runs pnpm start in the repo folder."
        }
    }

    static func resolve(choice: HostSourceKind?, repoFolder: String, bundled: BundledHost?, home: URL, isRepo: (String) -> Bool) -> HostSource? {
        let folder = repoFolder.trimmingCharacters(in: .whitespacesAndNewlines)
        if choice == .bundled, let bundled { return .bundled(bundled, home: home) }
        if choice == .repo, !folder.isEmpty { return .repo(folder: folder) }
        if !folder.isEmpty, isRepo(folder) { return .repo(folder: folder) }
        if let bundled { return .bundled(bundled, home: home) }
        return folder.isEmpty ? nil : .repo(folder: folder)
    }
}
