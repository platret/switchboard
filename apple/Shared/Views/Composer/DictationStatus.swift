import SwiftUI

struct DictationStatus: View {
    let state: SpeechState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .preparing:
            Label("Getting ready to listen", systemImage: "mic").font(.footnote).foregroundStyle(.secondary)
        case .listening:
            Label {
                Text("Listening. Tap the microphone when you are done.")
            } icon: {
                Image(systemName: "waveform").symbolEffect(.variableColor.iterative, isActive: !reduceMotion)
            }
            .font(.footnote)
            .foregroundStyle(Palette.danger)
        case .denied, .unavailable, .failed:
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(state.message ?? "Dictation is not available.", systemImage: "mic.slash").foregroundStyle(Palette.danger)
                if state == .denied, let url = SystemSettings.privacyURL {
                    Link("Open Settings", destination: url)
                }
            }
            .font(.footnote)
        }
    }
}
