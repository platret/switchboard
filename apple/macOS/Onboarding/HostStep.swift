import SwiftUI

struct HostStep: View {
    let host: HostController

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var phase: HostPhase {
        HostPhase(host.state, ownsProcess: host.ownsProcess)
    }

    private var title: String {
        switch phase {
        case .idle: "Start the host"
        case .working: host.state == .stopping ? "Restarting the host" : "Starting the host"
        case .running: "The host is running"
        case .failed: "The host did not start"
        }
    }

    private var detail: String {
        switch phase {
        case .idle:
            "The host runs your agents on this Mac. It keeps going while the window is closed."
        case .working:
            host.source?.startingDetail ?? "Looking for the host on this Mac."
        case .running(owned: true):
            "Your agents run on this Mac now. Quitting Switchboard stops the host."
        case .running(owned: false):
            "Switchboard found a host already running on port \(host.port) and uses it as it is."
        case .failed(let message):
            HostStep.failureDetail(message, log: host.log.lines)
        }
    }

    private var showsLog: Bool {
        guard case .failed(let message) = phase else { return false }
        return message.hasSuffix(HostController.logHint)
    }

    /// A start that died points at the log, so the subtitle shows the host's own error line
    /// instead of repeating the title. Other failures already say what to do.
    static func failureDetail(_ message: String, log: [String]) -> String {
        guard message.hasSuffix(HostController.logHint) else { return message }
        let prefix = "Error: "
        if let error = log.last(where: { $0.hasPrefix(prefix) }) {
            return String(error.dropFirst(prefix.count))
        }
        return "Here is the end of its log. Fix the problem, then try again."
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            HostBadge(phase: phase)
                .animation(reduceMotion ? OnboardingMotion.fade : OnboardingMotion.settle, value: phase)
                .reveal(0)
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 26, weight: .semibold))
                    .contentTransition(.opacity)
                    .accessibilityAddTraits(.isHeader)
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 460)
                    .contentTransition(.opacity)
            }
            .animation(OnboardingMotion.fade, value: phase)
            .reveal(1)
            if showsLog {
                HostLogTail(lines: host.log.lines)
                    .frame(maxWidth: OnboardingView.cardWidth)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .contain)
    }
}
