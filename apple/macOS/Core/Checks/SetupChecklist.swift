import Foundation

enum SetupChecklist {
    static func checks(for snapshot: SystemSnapshot?) -> [SetupCheck] {
        guard let snapshot else {
            return SetupCheck.Kind.allCases.map { SetupCheck(kind: $0, level: .checking, detail: "Checking…") }
        }
        return [host(snapshot), claude(snapshot), claudeApp(snapshot), tailscale(snapshot), notifications(snapshot)]
    }

    static func requiredPassed(_ checks: [SetupCheck]) -> Bool {
        checks.filter(\.isRequired).allSatisfy { $0.level == .ready }
    }

    static func host(_ snapshot: SystemSnapshot) -> SetupCheck {
        if snapshot.isHostRunning {
            return SetupCheck(kind: .host, level: .ready, detail: "Running on port \(snapshot.port).")
        }
        switch snapshot.runtime {
        case .bundled:
            return SetupCheck(kind: .host, level: .ready, detail: "Built into Switchboard and ready to start.")
        case .repo(let tools) where tools.isReady:
            return SetupCheck(kind: .host, level: .ready, detail: "Runs from your clone with Node \(tools.node?.description ?? "") and pnpm.")
        case .repo(let tools) where !tools.hasNode:
            return SetupCheck(kind: .host, level: .needed, detail: "Your clone needs Node \(ToolVersion.nodeMinimum) or later.", action: .getNode)
        case .repo(let tools) where !(tools.node.map({ $0 >= .nodeMinimum }) ?? false):
            let found = tools.node.map { "This Mac has \($0)." } ?? "Switchboard could not read its version."
            return SetupCheck(kind: .host, level: .needed, detail: "Your clone needs Node \(ToolVersion.nodeMinimum) or later. \(found)", action: .getNode)
        case .repo:
            return SetupCheck(kind: .host, level: .needed, detail: "Your clone needs pnpm to start the host.", action: .getPnpm)
        case .missing:
            return SetupCheck(kind: .host, level: .needed, detail: "No host found. Choose your Switchboard clone in Settings, Connection.")
        }
    }

    static func claude(_ snapshot: SystemSnapshot) -> SetupCheck {
        if snapshot.isClaudeSignedIn {
            return SetupCheck(kind: .claude, level: .ready, detail: "Signed in. Agents run on your Claude account.")
        }
        if snapshot.claudePath == nil {
            return SetupCheck(kind: .claude, level: .needed, detail: "Agents run on your Claude account. Install Claude Code, then sign in.", action: .getClaudeCode)
        }
        return SetupCheck(kind: .claude, level: .needed, detail: "Agents run on your Claude account. Sign in once in Terminal.", action: .signIn)
    }

    static func claudeApp(_ snapshot: SystemSnapshot) -> SetupCheck {
        let app = snapshot.claudeApp
        if app.isRunning { return SetupCheck(kind: .claudeApp, level: .ready, detail: "Installed and open.") }
        if app.isInstalled { return SetupCheck(kind: .claudeApp, level: .ready, detail: "Installed.", action: .openClaude) }
        return SetupCheck(kind: .claudeApp, level: .optional, detail: "Optional. Agents run without it.", action: .getClaude)
    }

    static func tailscale(_ snapshot: SystemSnapshot) -> SetupCheck {
        if let address = snapshot.tailscaleAddress {
            return SetupCheck(kind: .tailscale, level: .ready, detail: "Connected at \(address). Your iPhone can reach this Mac.")
        }
        let app = snapshot.tailscale
        if app.isRunning { return SetupCheck(kind: .tailscale, level: .optional, detail: "Open but not connected. Sign in to reach this Mac from your iPhone.", action: .openTailscale) }
        if app.isInstalled { return SetupCheck(kind: .tailscale, level: .optional, detail: "Installed but closed. Only the iPhone app needs it.", action: .openTailscale) }
        return SetupCheck(kind: .tailscale, level: .optional, detail: "Optional. Lets your iPhone reach this Mac privately.", action: .getTailscale)
    }

    static func notifications(_ snapshot: SystemSnapshot) -> SetupCheck {
        switch snapshot.notifications {
        case .allowed:
            SetupCheck(kind: .notifications, level: .ready, detail: "On. Approval requests reach you with Allow and Deny.")
        case .notDetermined:
            SetupCheck(kind: .notifications, level: .optional, detail: "Hear about approval requests while Switchboard is in the background.", action: .allowNotifications)
        case .denied:
            SetupCheck(kind: .notifications, level: .optional, detail: "Off in System Settings. Turn them on to hear about approvals.", action: .openNotificationSettings)
        case .unknown:
            SetupCheck(kind: .notifications, level: .checking, detail: "Checking…")
        }
    }
}
