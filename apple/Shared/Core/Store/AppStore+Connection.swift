import Foundation

extension AppStore {
    static let staleAfter: TimeInterval = 20

    var isLinkStale: Bool {
        connection == .connected && client.silence >= AppStore.staleAfter
    }

    var needsSetup: Bool {
        connection == .notConfigured || connection == .tokenRejected
    }

    func start() {
        adoptLaunchCredentials()
        connect()
    }

    func connect() {
        connecting?.cancel()
        connecting = Task { [weak self] in await self?.openConnection() }
    }

    func refreshConnection() {
        switch connection {
        case .notConfigured, .tokenRejected: return
        case .connected where !isLinkStale: return
        default: connect()
        }
    }

    func disconnect() {
        connecting?.cancel()
        client.disconnect()
        connection = .notConfigured
    }

    func resolveToken() async -> String? {
        #if os(macOS)
        let saved = settings.endpoint?.isLocal == false ? tokens.read() : nil
        if let saved { return saved }
        if let fromRepo = await repoToken() { return fromRepo }
        #endif
        return tokens.read()
    }

    func readingFolders<Value: Sendable>(_ work: @escaping @Sendable () -> Value) async -> Value {
        let slow = Task { [weak self] in
            try await Task.sleep(for: .seconds(1.5))
            self?.isWaitingForFolderAccess = true
        }
        let value = await Task.detached { work() }.value
        slow.cancel()
        isWaitingForFolderAccess = false
        return value
    }

    private func repoToken() async -> String? {
        let folder = settings.repoFolder
        return await readingFolders { EnvFile.token(inFolder: folder) }
    }

    private func adoptLaunchCredentials() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        guard let host = environment["SWITCHBOARD_HOST"], let endpoint = HostEndpoint(string: host) else { return }
        guard let token = environment[EnvFile.tokenKey], !token.isEmpty else { return }
        settings.hostURL = endpoint.displayString
        tokens.save(token)
        #endif
    }

    private func openConnection() async {
        let token = await resolveToken()
        guard !Task.isCancelled else { return }
        guard let endpoint = settings.endpoint, let token else {
            client.disconnect()
            connection = .notConfigured
            return
        }
        client.connect(to: endpoint, token: token)
    }

    func saveConnection(host: String, token: String) throws {
        guard let endpoint = HostEndpoint(string: host) else { throw ClientError.invalidHost }
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ClientError.missingToken }
        settings.hostURL = endpoint.displayString
        tokens.save(trimmed)
        connect()
    }

    func pair(with link: PairingLink) {
        settings.hostURL = link.endpoint.displayString
        tokens.save(link.token)
        connect()
    }

    func forgetConnection() {
        tokens.clear()
        disconnect()
        isReady = false
        agents = [:]
        items = [:]
        drafts = [:]
        approvals = []
        loadedHistories = []
        pendingAnswers = [:]
        selectedAgentId = nil
    }
}
