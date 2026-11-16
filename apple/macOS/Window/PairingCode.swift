import SwiftUI

struct PairingCode: View {
    let link: PairingLink?
    let problem: String

    private static let side: CGFloat = 228

    var body: some View {
        Group {
            if let link, let image = QRCode.image(for: link.string) {
                Image(decorative: image, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Surface.hairline, lineWidth: 1))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                    .accessibilityElement()
                    .accessibilityLabel("Pairing code for the iPhone app")
                    .accessibilityAddTraits(.isImage)
            } else {
                Text(problem)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Surface.sunken, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .frame(width: PairingCode.side, height: PairingCode.side)
    }
}
