import Foundation

@MainActor
final class SwitchboardClient {
    static let unauthorizedCloseCode = 4401
    static let silenceLimit: TimeInterval = 35
    static let handshakeLimit: TimeInterval = 10

    var onState: ((ConnectionState) -> Void)?
    var onMessage: ((ServerMessage) -> Void)?
    var onSendFailure: ((ClientMessage) -> Void)?

    let session: URLSession
    private(set) var endpoint: HostEndpoint?
    private(set) var token: String?
    private var socket: URLSessionWebSocketTask?
    private var runner: Task<Void, Never>?
    private var lastHeard = Date()
    private var authenticated = false

    var silence: TimeInterval {
        Date().timeIntervalSince(lastHeard)
    }

    init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func connect(to endpoint: HostEndpoint, token: String) {
        disconnect()
        self.endpoint = endpoint
        self.token = token
        runner = Task { [weak self] in await self?.run(endpoint: endpoint, token: token) }
    }

    func disconnect() {
        runner?.cancel()
        runner = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        authenticated = false
    }

    @discardableResult
    func send(_ message: ClientMessage) -> Bool {
        guard authenticated, let socket, let text = try? JSONCoding.string(message) else { return false }
        socket.send(.string(text)) { [weak self] error in
            guard error != nil else { return }
            Task { @MainActor in self?.sendFailed(message, on: socket) }
        }
        return true
    }

    private func sendFailed(_ message: ClientMessage, on task: URLSessionWebSocketTask) {
        if socket === task { task.cancel(with: .goingAway, reason: nil) }
        onSendFailure?(message)
    }

    private func run(endpoint: HostEndpoint, token: String) async {
        var attempt = 0
        onState?(.connecting)
        while !Task.isCancelled {
            let outcome = await serve(endpoint: endpoint, token: token)
            if Task.isCancelled { return }
            if outcome == .rejected {
                onState?(.tokenRejected)
                return
            }
            attempt = outcome == .dropped ? 1 : attempt + 1
            onState?(.reconnecting)
            try? await Task.sleep(for: .seconds(Backoff.delay(attempt: attempt)))
        }
    }

    private func serve(endpoint: HostEndpoint, token: String) async -> SessionOutcome {
        guard let url = endpoint.webSocketURL, let greeting = try? JSONCoding.string(ClientMessage.auth(token: token)) else { return .failed }
        let task = session.webSocketTask(with: url)
        task.maximumMessageSize = 64 * 1024 * 1024
        socket = task
        authenticated = false
        lastHeard = Date()
        task.resume()
        let watchdog = Task { [weak self] in await self?.watch(task) }
        defer {
            watchdog.cancel()
            task.cancel(with: .goingAway, reason: nil)
        }
        var wasAuthenticated = false
        do {
            try await task.send(.string(greeting))
            while !Task.isCancelled {
                let frame = try await task.receive()
                lastHeard = Date()
                guard socket === task, let message = decode(frame) else { continue }
                if message == .authOk {
                    authenticated = true
                    wasAuthenticated = true
                    onState?(.connected)
                }
                onMessage?(message)
            }
        } catch {
            if task.closeCode.rawValue == SwitchboardClient.unauthorizedCloseCode { return .rejected }
        }
        if socket === task { authenticated = false }
        return wasAuthenticated ? .dropped : .failed
    }

    private func watch(_ task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            let limit = authenticated ? SwitchboardClient.silenceLimit : SwitchboardClient.handshakeLimit
            if !Task.isCancelled, Date().timeIntervalSince(lastHeard) > limit {
                task.cancel(with: .goingAway, reason: nil)
                return
            }
        }
    }

    private func decode(_ frame: URLSessionWebSocketTask.Message) -> ServerMessage? {
        switch frame {
        case .string(let text): ServerMessage.parse(text)
        case .data(let data): try? JSONCoding.decoder.decode(ServerMessage.self, from: data)
        @unknown default: nil
        }
    }
}
