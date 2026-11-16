import SwiftUI

struct OnboardingFooter: View {
    let model: OnboardingModel

    private var host: HostController {
        model.host
    }

    var body: some View {
        HStack(spacing: 10) {
            if model.step != .welcome, model.step != .done {
                Button("Back") { model.goBack() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .disabled(host.state == .starting)
            }
            Spacer(minLength: 0)
            if let secondary {
                OnboardingButton(title: secondary.title, kind: .secondary, action: secondary.action)
                    .transition(.opacity)
            }
            OnboardingButton(title: primary.title, isDefault: true, action: primary.action)
                .disabled(!primary.isEnabled)
        }
        .animation(OnboardingMotion.fade, value: secondary?.title)
    }

    private var primary: (title: String, isEnabled: Bool, action: () -> Void) {
        switch model.step {
        case .welcome:
            return ("Get started", true, model.advance)
        case .checks:
            if model.checks.snapshot != nil, !model.checks.requiredPassed { return ("Continue anyway", true, model.advance) }
            return ("Continue", model.checks.requiredPassed, model.advance)
        case .projects:
            if model.projects.isEditable, model.projects.projects.isEmpty {
                return ("Skip for now", true, { Task { await model.saveProjectsAndContinue() } })
            }
            let title = host.isRunning && !model.projects.hasChanges ? "Continue" : "Start host"
            return (title, true, { Task { await model.saveProjectsAndContinue() } })
        case .host:
            if case .failed = host.state { return ("Retry", true, { Task { await model.startHost() } }) }
            if host.state == .stopped { return ("Start host", true, { Task { await model.startHost() } }) }
            return ("Continue", host.isRunning, model.advance)
        case .phone:
            return (model.pairingLink == nil ? "Skip for now" : "Continue", true, model.advance)
        case .done:
            return ("Open Switchboard", true, model.finish)
        }
    }

    /// Only the host step offers a second way on: a Mac whose host cannot start yet,
    /// or that uses a host elsewhere, can still finish setup.
    private var secondary: (title: String, action: () -> Void)? {
        guard model.step == .host else { return nil }
        switch host.state {
        case .failed, .stopped: return ("Set up later", model.advance)
        default: return nil
        }
    }
}
