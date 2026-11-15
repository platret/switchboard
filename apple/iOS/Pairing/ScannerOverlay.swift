import SwiftUI

struct ScannerOverlay: View {
    let wasRejected: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white, lineWidth: 3)
                .frame(width: 240, height: 240)
                .accessibilityHidden(true)
            Text(wasRejected ? "That is not a Switchboard pairing code. Open Pair iPhone in Switchboard on your Mac." : "Point the camera at the code shown by Pair iPhone on your Mac.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 24)
            Spacer()
        }
    }
}
