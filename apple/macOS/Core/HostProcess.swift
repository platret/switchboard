import Foundation

final class HostProcess: @unchecked Sendable {
    static let searchPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    private let process = Process()
    private let pipe = Pipe()

    var isRunning: Bool {
        process.isRunning
    }

    var group: Int32 {
        process.processIdentifier
    }

    func start(command: String, folder: String, onOutput: @escaping @Sendable (String) -> Void, onExit: @escaping @Sendable (Int32) -> Void) throws {
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = HostProcess.searchPath
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = URL(fileURLWithPath: (folder as NSString).expandingTildeInPath)
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = pipe
        process.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return handle.readabilityHandler = nil }
            onOutput(String(decoding: data, as: UTF8.self))
        }
        process.terminationHandler = { finished in
            onExit(finished.terminationStatus)
        }
        try process.run()
    }

    func terminate() {
        guard process.isRunning else { return }
        if killpg(process.processIdentifier, SIGTERM) != 0 { process.terminate() }
    }
}
