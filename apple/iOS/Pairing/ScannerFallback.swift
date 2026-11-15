import SwiftUI

struct ScannerFallback: View {
    let state: ScannerState
    let wasRejected: Bool
    let onPaste: (String) -> Void

    @Environment(\.openURL) private var openURL

    private static let pasteTint = Color(red: 39 / 255, green: 71 / 255, blue: 216 / 255)

    private var title: String {
        state == .denied ? "Camera access is off" : "No camera available"
    }

    private var explanation: String {
        if wasRejected { return "That is not a Switchboard pairing link. It looks like http://100.64.0.1:4317/#token=..." }
        if state == .denied { return "Allow the camera in Settings, or copy the pairing link on your Mac and paste it here." }
        return "Copy the pairing link on your Mac and paste it here, or close this and enter the address by hand."
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "camera.badge.ellipsis")
        } description: {
            Text(explanation).foregroundStyle(wasRejected ? Palette.danger : Color.secondary)
        } actions: {
            PasteButton(payloadType: String.self) { strings in
                onPaste(strings.first ?? "")
            }
            .tint(ScannerFallback.pasteTint)
            .accessibilityLabel("Paste pairing link")
            if state == .denied, let url = SystemSettings.privacyURL {
                Button("Open Settings") { openURL(url) }
            }
        }
    }
}
