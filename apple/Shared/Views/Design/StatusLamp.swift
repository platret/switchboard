import SwiftUI

struct StatusLamp: View {
    let status: AgentStatus
    var size: CGFloat = 12

    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    private var diameter: CGFloat {
        size * scale
    }

    private var lineWidth: CGFloat {
        max(1.5, diameter * 0.16)
    }

    var body: some View {
        lamp
            .frame(width: diameter, height: diameter)
            .foregroundStyle(Palette.lamp(status))
            .accessibilityElement()
            .accessibilityLabel(status.label)
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private var lamp: some View {
        switch status {
        case .idle:
            Circle().strokeBorder(lineWidth: lineWidth).opacity(0.75)
        case .working:
            SpinningArc(lineWidth: lineWidth)
        case .waiting:
            ZStack {
                PulseRing(startScale: 0.6, endScale: 1, lineWidth: 1.5)
                Circle().scaleEffect(0.62)
            }
        case .error:
            RoundedRectangle(cornerRadius: diameter * 0.24, style: .continuous).padding(diameter * 0.08)
        }
    }
}
