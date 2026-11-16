import Foundation

enum SwitchboardHome {
    static let folderMode = 0o700
    static let secretMode = 0o600
    static let envName = ".env"
    static let projectsName = "projects.json"
    static let rolesName = "roles.json"

    static var standard: URL {
        URL.applicationSupportDirectory.appending(path: "Switchboard")
    }

    static func displayPath(_ path: String) -> String {
        (path as NSString).abbreviatingWithTildeInPath
    }

    static func prepare(_ home: URL) throws {
        let manager = FileManager.default
        var isDirectory: ObjCBool = false
        if manager.fileExists(atPath: home.path, isDirectory: &isDirectory), isDirectory.boolValue {
            try manager.setAttributes([.posixPermissions: folderMode], ofItemAtPath: home.path)
        } else {
            try manager.createDirectory(at: home, withIntermediateDirectories: true, attributes: [.posixPermissions: folderMode])
        }
        try ensureToken(in: home)
    }

    static func ensureToken(in home: URL) throws {
        let file = home.appending(path: envName)
        let existing = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
        if let token = EnvFile.parse(existing)[EnvFile.tokenKey], !token.isEmpty {
            return try FileManager.default.setAttributes([.posixPermissions: secretMode], ofItemAtPath: file.path)
        }
        guard let token = AccessToken.make() else { throw CocoaError(.fileWriteUnknown) }
        let separator = existing.isEmpty || existing.hasSuffix("\n") ? "" : "\n"
        try writePrivately(Data((existing + separator + "\(EnvFile.tokenKey)=\(token)\n").utf8), to: file)
    }

    static func writePrivately(_ data: Data, to file: URL) throws {
        let staging = file.deletingLastPathComponent().appending(path: ".\(file.lastPathComponent).\(UUID().uuidString)")
        guard FileManager.default.createFile(atPath: staging.path, contents: data, attributes: [.posixPermissions: secretMode]) else {
            throw CocoaError(.fileWriteNoPermission)
        }
        guard rename(staging.path, file.path) == 0 else {
            try? FileManager.default.removeItem(at: staging)
            throw CocoaError(.fileWriteUnknown)
        }
    }
}
