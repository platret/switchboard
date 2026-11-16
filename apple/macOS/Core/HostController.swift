import Foundation
import Observation

@MainActor
@Observable
final class HostController {
    static let startTimeout: TimeInterval = 90
    static let missingSource = "Choose the folder of your Switchboard clone in Settings, Connection, then start the host."
    static let logHint = "Check the log."

    private(set) var state: HostState = .unknown
    private(set) var log = HostLog()
    private(set) var adoptedGroup: Int32?
    private(set) var source: HostSource?
    private(set) var port = HostEndpoint.defaultPort

    @ObservationIgnored let bundled: BundledHost?
    @ObservationIgnored let home: URL
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var process: HostProcess?
    @ObservationIgnored private var isReading = false

    init(settings: AppSettings, bundled: BundledHost? = BundledHost.find(), home: URL = SwitchboardHome.standard) {
        self.settings = settings
        self.bundled = bundled
        self.home = home
        source = HostSource.resolve(choice: settings.hostSource.flatMap(HostSourceKind.init(rawValue:)), repoFolder: settings.repoFolder, bundled: bundled, home: home) { _ in true }
    }

    var isRunning: Bool {
        state == .running
    }

    var ownsProcess: Bool {
        process?.isRunning == true || adoptedGroup != nil
    }

    var webURL: URL? {
        URL(string: "http://127.0.0.1:\(port)/")
    }

    func refresh() async {
        guard state != .starting, state != .stopping else { return }
        await readConfiguration()
        let listening = await isPortTaken()
        let adopted = listening && process == nil ? await savedGroup() : nil
        let conflict = listening && adopted == nil ? await foreignHostConflict() : nil
        guard state != .starting, state != .stopping else { return }
        adoptedGroup = adopted
        if let conflict {
            state = .failed(conflict)
        } else if listening {
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
        await readConfiguration()
        if await isPortTaken() { return state = await foreignHostConflict().map(HostState.failed) ?? .running }
        guard let source else { return state = .failed(HostController.missingSource) }
        if case .bundled(_, let home) = source {
            do {
                try await Task.detached { try SwitchboardHome.prepare(home) }.value
            } catch {
                return state = .failed("Switchboard could not set up \(SwitchboardHome.displayPath(home.path)). \(error.localizedDescription)")
            }
        }
        let launch = source.launch
        log.note(launch.note)
        let launched = HostProcess()
        do {
            try launched.start(launch) { [weak self] chunk in
                Task { @MainActor in self?.log.append(chunk) }
            } onExit: { [weak self] status in
                Task { @MainActor in self?.exited(launched, status: status) }
            }
            process = launched
            settings.hostProcessGroup = launched.group
            await waitUntilListening()
        } catch {
            state = .failed("\(launch.failure) \(error.localizedDescription)")
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

    func restart() async {
        if ownsProcess { await stop() }
        await start()
    }

    func releaseProcess() {
        process?.terminate()
        if let adoptedGroup { killpg(adoptedGroup, SIGTERM) }
    }

    func readConfiguration() async {
        if !isReading {
            isReading = true
            let choice = settings.hostSource.flatMap(HostSourceKind.init(rawValue:))
            let folder = settings.repoFolder
            let bundled = bundled
            let home = home
            Task { [weak self] in
                let found = await Task.detached { () -> (HostSource?, Int) in
                    let source = HostSource.resolve(choice: choice, repoFolder: folder, bundled: bundled, home: home, isRepo: RepoLocator.isRepo(path:))
                    return (source, HostProbe.port(inFolder: source?.envFolder ?? ""))
                }.value
                self?.source = found.0
                self?.port = found.1
                self?.isReading = false
            }
        }
        for _ in 0..<10 where isReading {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func savedGroup() async -> Int32? {
        guard let saved = settings.hostProcessGroup, saved > 1 else { return nil }
        let listeners = await HostProbe.listenerPids(port: port)
        return listeners.contains { getpgid($0) == saved } ? saved : nil
    }

    /// The built-in host keeps its own token, so a host it did not start that rejects that token,
    /// such as one running from a clone, is reported instead of being used as the built-in one.
    private func foreignHostConflict() async -> String? {
        guard process == nil, case .bundled(_, let home) = source else { return nil }
        let token = await Task.detached { EnvFile.token(inFolder: home.path) }.value
        if let token, await HostProbe.accepts(token: token, port: port) { return nil }
        let env = SwitchboardHome.displayPath(home.appending(path: SwitchboardHome.envName).path)
        return "Another host already uses port \(port). Stop it, or give the built-in host its own port with \(EnvFile.portKey) in \(env)."
    }

    private func isPortTaken() async -> Bool {
        if await HostProbe.isListening(port: port) { return true }
        return await !HostProbe.listenerPids(port: port).isEmpty
    }

    private func waitUntilListening() async {
        let deadline = Date().addingTimeInterval(HostController.startTimeout)
        while state == .starting, Date() < deadline {
            if await HostProbe.isListening(port: port) { return state = .running }
            try? await Task.sleep(for: .milliseconds(500))
        }
        if state == .starting { state = .failed("The host did not answer on port \(port). \(HostController.logHint)") }
    }

    private func exited(_ finished: HostProcess, status: Int32) {
        guard process === finished else { return }
        process = nil
        settings.hostProcessGroup = nil
        log.note("The host process ended with status \(status)")
        if state == .starting { state = .failed("The host stopped while starting. \(HostController.logHint)") }
        if state == .running { state = .stopped }
    }
}
