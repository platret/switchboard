import Foundation

enum RepoLocator {
    static let folderName = "switchboard"
    static let parents = ["", "code", "Developer", "Projects", "dev", "src", "repos", "GitHub", "Desktop", "Desktop/Projects", "Documents", "Documents/Projects", "Documents/GitHub"]

    static func find(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> String? {
        parents
            .map { ($0.isEmpty ? home : home.appending(path: $0)).appending(path: folderName) }
            .first(where: isRepo)?
            .path
    }

    static func isRepo(path: String) -> Bool {
        isRepo(URL(fileURLWithPath: (path as NSString).expandingTildeInPath))
    }

    static func isRepo(_ folder: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.appending(path: "host").path, isDirectory: &isDirectory), isDirectory.boolValue else { return false }
        guard let data = try? Data(contentsOf: folder.appending(path: "package.json")) else { return false }
        return (try? JSONDecoder().decode(Package.self, from: data))?.name == folderName
    }

    private struct Package: Decodable {
        let name: String
    }
}
