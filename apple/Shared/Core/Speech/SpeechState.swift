import Foundation

enum SpeechState: Hashable, Sendable {
    case idle
    case preparing
    case listening
    case denied
    case unavailable
    case failed

    var message: String? {
        switch self {
        case .idle, .preparing, .listening: nil
        case .denied: "Allow the microphone and speech recognition for Switchboard in Settings."
        case .unavailable: "Dictation is not available for this language right now."
        case .failed: "Dictation stopped because of an audio problem. Try again."
        }
    }
}
