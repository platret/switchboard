import SwiftUI

struct HostBadge: View {
    let phase: HostPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let side: CGFloat = 68

    var body: some View {
        ZStack {
            switch phase {
            case .idle:
                Circle().strokeBorder(Color.secondary.opacity(0.5), lineWidth: 3)
                Image(systemName: "power").font(.system(size: 24, weight: .semibold)).foregroundStyle(.secondary)
            case .working:
                SpinningArc(lineWidth: 4).foregroundStyle(Palette.cobalt)
            case .running:
                if !reduceMotion { SettleRing() }
                Circle().fill(Color.green)
                Image(systemName: "checkmark").font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
            case .failed:
                Circle().fill(Palette.danger)
                Image(systemName: "exclamationmark").font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
            }
        }
        .frame(width: HostBadge.side, height: HostBadge.side)
        .id(HostBadge.identity(of: phase))
        .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
        .accessibilityHidden(true)
    }

    private static func identity(of phase: HostPhase) -> String {
        switch phase {
        case .idle: "idle"
        case .working: "working"
        case .running: "running"
        case .failed: "failed"
        }
    }
}
