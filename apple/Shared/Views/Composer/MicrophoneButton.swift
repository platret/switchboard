import SwiftUI

struct MicrophoneButton: View {
    let state: SpeechState
    let action: () -> Void

    var body: some View {
        switch state {
        case .listening:
            ComposerButton(symbol: "waveform", label: "Stop dictation", fill: Palette.danger, action: action)
                .background { PulseRing(startScale: 0.8, endScale: 1.25).foregroundStyle(Palette.danger) }
                .accessibilityValue("Listening")
        case .preparing:
            ComposerButton(symbol: "mic.fill", label: "Stop dictation", fill: Palette.danger.opacity(0.5), action: action)
                .accessibilityValue("Getting ready")
        case .idle, .denied, .unavailable, .failed:
            ComposerButton(symbol: "mic", label: "Dictate message", action: action)
        }
    }
}
