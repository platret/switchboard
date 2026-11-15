import Foundation

struct SpeechUpdate: Hashable, Sendable {
    var text: String?
    var isFinal: Bool
    var failed: Bool
}
