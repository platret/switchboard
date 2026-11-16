import Foundation

enum ProjectsFile {
    static let defaultRoles = ["dev", "tester", "reviewer"]
    static let fallbackId = "project"

    static func slug(_ name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
        var slug = ""
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar), scalar.isASCII {
                slug.unicodeScalars.append(scalar)
            } else if !slug.isEmpty, !slug.hasSuffix("-") {
                slug.append("-")
            }
        }
        while slug.hasSuffix("-") { slug.removeLast() }
        return slug.isEmpty ? fallbackId : slug
    }

    static func uniqueId(for name: String, taken: Set<String>) -> String {
        let base = slug(name)
        guard taken.contains(base) else { return base }
        var counter = 2
        while taken.contains("\(base)-\(counter)") { counter += 1 }
        return "\(base)-\(counter)"
    }

    static func displayName(for folder: URL) -> String {
        let name = folder.standardizedFileURL.lastPathComponent
        return name.isEmpty || name == "/" ? "Project" : name
    }

    static func project(for folder: URL, taken: Set<String>, roles: [String] = defaultRoles) -> Project {
        let name = displayName(for: folder)
        let path = (folder.standardizedFileURL.path as NSString).abbreviatingWithTildeInPath
        return Project(id: uniqueId(for: name, taken: taken), name: name, path: path, agents: roles)
    }

    static func adding(_ folders: [URL], to projects: [Project], roles: [String] = defaultRoles) -> [Project] {
        var result = projects
        var known = Set(projects.map { expanded($0.path) })
        for folder in folders {
            let path = folder.standardizedFileURL.path
            guard !known.contains(path) else { continue }
            known.insert(path)
            result.append(project(for: folder, taken: Set(result.map(\.id)), roles: roles))
        }
        return result
    }

    static func expanded(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
    }

    static func encode(_ projects: [Project]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        var data = try encoder.encode(projects)
        data.append(contentsOf: Array("\n".utf8))
        return data
    }

    static func decode(_ data: Data) throws -> [Project] {
        try JSONDecoder().decode([Project].self, from: data)
    }

    static func read(_ file: URL) -> [Project]? {
        (try? load(file)) ?? nil
    }

    /// Nil when there is no file yet; throws when a file is there but cannot be read as a project list.
    static func load(_ file: URL) throws -> [Project]? {
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return try decode(Data(contentsOf: file))
    }

    static func write(_ projects: [Project], to file: URL) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: SwitchboardHome.folderMode])
        try encode(projects).write(to: file, options: .atomic)
    }
}
