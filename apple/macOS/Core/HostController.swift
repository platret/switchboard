import Foundation
import Observation

@MainActor
@Observable
final class HostController {
    static let command = "pnpm start"
    static let startTimeout: TimeInterval = 90

    private(set) var state: HostState = .unknown
    private(set) var log = HostLog()
    private(set) var adoptedGroup: Int32?

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var process: HostProcess?
    @ObservationIgnored private var isReadingPort = false

    init(settings: AppSettings) {
        self.settings = settings
    }

    var isRunning: Bool {
        state == .running
    }

    var ownsProcess: Bool {
        process?.isRunning == true || adoptedGroup != nil
    }

    private(set) var port = HostEndpoint.defaultPort

    var webURL: URL? {
        URL(string: "http://127.0.0.1:\(port)/")
    }

    func refresh() async {
        guard state != .starting, state != .stopping else { return }
        await readPort()
        let listening = await isPortTaken()
        let adopted = listening && process == nil ? await savedGroup() : nil
        guard state != .starting, state != .stopping else { return }
        adoptedGroup = adopted
        if listening {
            state = .running
        } else if case .failed = state {
            return
        } else {
            state = .stopped
        }
    }

    func startIfNeeded() async {
        await refresh()
        if state == .stopped, settings.startsHostOnLaunch { await start() }
    }

    func start() async {
        guard state != .starting, state != .stopping, !ownsProcess else { return }
        state = .starting
        await readPort()
        if await isPortTaken() { return state = .running }
        guard !settings.repoFolder.isEmpty else { return state = .failed("Choose the folder of your Switchboard clone in Settings, Connection, then start the host.") }
        log.note("Starting the host in \(settings.repoFolder)")
        let launched = HostProcess()
        do {
            try launched.start(command: HostController.command, folder: settings.repoFolder) { [weak self] chunk in
                Task { @MainActor in self?.log.append(chunk) }
            } onExit: { [weak self] status in
                Task { @MainActor in self?.exited(launched, status: status) }
            }
            process = launched
            settings.hostProcessGroup = launched.group
            await waitUntilListening()
        } catch {
            state = .failed("Could not run pnpm in \(settings.repoFolder). \(error.localizedDescription)")
        }
    }

    func stop() async {
        guard state != .stopping, ownsProcess else { return }
        state = .stopping
        log.note("Stopping the host")
        let stopping = process
        let adopted = adoptedGroup
        releaseProcess()
        for _ in 0..<40 {
            let lingers = adopted == nil ? stopping?.isRunning == true : await isPortTaken()
            guard lingers else { break }
            try? await Task.sleep(for: .milliseconds(250))
        }
        if process === stopping { process = nil }
        adoptedGroup = nil
        settings.hostProcessGroup = nil
        state = await HostProbe.isListening(port: port) ? .running : .stopped
    }

    func releaseProcess() {
        process?.terminate()
        if let adoptedGroup { killpg(adoptedGroup, SIGTERM) }
    }

    private func savedGroup() async -> Int32? {
        guard let saved = settings.hostProcessGroup, saved > 1 else { return nil }
        let listeners = await HostProbe.listenerPids(port: port)
        return listeners.contains { getpgid($0) == saved } ? saved : nil
    }

    private func isPortTaken() async -> Bool {
        if await HostProbe.isListening(port: port) { return true }
        return await !HostProbe.listenerPids(port: port).isEmpty
    }

    private func readPort() async {
        if !isReadingPort {
            isReadingPort = true
            let folder = settings.repoFolder
            Task { [weak self] in
                let found = await Task.detached { HostProbe.port(inFolder: folder) }.value
                self?.port = found
                self?.isReadingPort = false
            }
        }
        for _ in 0..<10 where isReadingPort {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func waitUntilListening() async {
        let deadline = Date().addingTimeInterval(HostController.startTimeout)
        while state == .starting, Date() < deadline {
            if await HostProbe.isListening(port: port) { return state = .running }
            try? await Task.sleep(for: .milliseconds(500))
        }
        if state == .starting { state = .failed("The host did not answer on port \(port). Check the log.") }
    }

    private func exited(_ finished: HostProcess, status: Int32) {
        guard process === finished else { return }
        process = nil
        settings.hostProcessGroup = nil
        log.note("The host process ended with status \(status)")
        if state == .starting { state = .failed("The host stopped while starting. Check the log.") }
        if state == .running { state = .stopped }
    }
}
