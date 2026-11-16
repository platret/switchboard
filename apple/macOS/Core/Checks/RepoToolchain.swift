import Foundation

struct RepoToolchain: Hashable, Sendable {
    var node: ToolVersion?
    var hasNode = false
    var hasPnpm = false

    var isReady: Bool {
        hasPnpm && (node.map { $0 >= .nodeMinimum } ?? false)
    }

    static func executable(named name: String, searchPath: String = HostProcess.searchPath) -> String? {
        searchPath.split(separator: ":")
            .map { URL(fileURLWithPath: String($0)).appending(path: name).path }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func find(searchPath: String = HostProcess.searchPath) -> RepoToolchain {
        let node = executable(named: "node", searchPath: searchPath)
        return RepoToolchain(node: node.flatMap(version), hasNode: node != nil, hasPnpm: executable(named: "pnpm", searchPath: searchPath) != nil)
    }

    static func version(of executable: String) -> ToolVersion? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["--version"]
        process.environment = ["PATH": HostProcess.searchPath]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return ToolVersion(String(decoding: data, as: UTF8.self))
    }
}
