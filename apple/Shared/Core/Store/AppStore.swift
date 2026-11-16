import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    var connection: ConnectionState = .connecting
    var isReady = false
    var projects: [Project] = []
    var roles: [Role] = []
    var agents: [String: Agent] = [:]
    var items: [String: [ChatItem]] = [:]
    var drafts: [String: [ChatDraft]] = [:]
    var approvals: [Approval] = [] {
        didSet { if approvals.map(\.id) != oldValue.map(\.id) { holdApprovalInput() } }
    }
    var hostInfo: HostInfo?
    var selectedProjectId: String?
    var selectedAgentId: String?
    var notice: String?
    var loadedHistories: Set<String> = []
    var pendingAnswers: [String: ApprovalAnswer] = [:]
    var isApprovalInputHeld = false
    var isWaitingForFolderAccess = false

    @ObservationIgnored let client: SwitchboardClient
    @ObservationIgnored let settings: AppSettings
    @ObservationIgnored let tokens: TokenStore
    @ObservationIgnored var notifications: NotificationPosting?
    @ObservationIgnored var approvalHold: Task<Void, Never>?
    @ObservationIgnored var connecting: Task<Void, Never>?
    /// The folder whose .env holds the local host's token. The Mac app points it at the host it runs.
    @ObservationIgnored var localEnvFolder: (() -> String)?

    init(client: SwitchboardClient? = nil, settings: AppSettings = AppSettings(), tokens: TokenStore = KeychainTokenStore(), notifications: NotificationPosting? = nil) {
        let client = client ?? SwitchboardClient()
        self.client = client
        self.settings = settings
        self.tokens = tokens
        self.notifications = notifications
        selectedProjectId = settings.lastProjectId
        client.onState = { [weak self] state in self?.connection = state }
        client.onMessage = { [weak self] message in self?.receive(message) }
        client.onSendFailure = { [weak self] message in self?.sendFailed(message) }
    }
}
