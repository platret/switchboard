import AppKit

struct AppPresence: Hashable, Sendable {
    var isInstalled = false
    var isRunning = false
    var location: URL?

    static func find(bundleIdentifiers: [String], paths: [String] = []) -> AppPresence {
        let workspace = NSWorkspace.shared
        let installed = bundleIdentifiers.lazy.compactMap { workspace.urlForApplication(withBundleIdentifier: $0) }.first
            ?? paths.lazy.map { URL(fileURLWithPath: $0) }.first { FileManager.default.fileExists(atPath: $0.path) }
        let running = bundleIdentifiers.contains { !NSRunningApplication.runningApplications(withBundleIdentifier: $0).isEmpty }
        return AppPresence(isInstalled: installed != nil || running, isRunning: running, location: installed)
    }
}
