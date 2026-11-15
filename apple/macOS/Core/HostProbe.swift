import Foundation

enum HostProbe {
    static func port(inFolder folder: String) -> Int {
        EnvFile.values(inFolder: folder)[EnvFile.portKey].flatMap { Int($0) } ?? HostEndpoint.defaultPort
    }

    static func isListening(port: Int) async -> Bool {
        guard let url = URL(string: "http://127.0.0.1:\(port)/") else { return false }
        var request = URLRequest(url: url, timeoutInterval: 1.5)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return (try? await URLSession.shared.data(for: request)) != nil
    }

    static func listenerPids(port: Int) async -> [Int32] {
        await Task.detached {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            process.arguments = ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN", "-t"]
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            guard (try? process.run()) != nil else { return [Int32]() }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let pids = String(decoding: data, as: UTF8.self).split(whereSeparator: \.isNewline).compactMap { Int32($0) }
            return Array(Set(pids)).sorted()
        }.value
    }
}
