import Foundation
import Observation
import Speech

@MainActor
@Observable
final class SpeechRecognizer {
    private(set) var state: SpeechState = .idle
    private(set) var transcript = ""

    @ObservationIgnored private var session: SpeechSession?
    @ObservationIgnored private var accumulator = TranscriptAccumulator()
    @ObservationIgnored private var generation = 0

    var isListening: Bool {
        state == .listening
    }

    var isBusy: Bool {
        state == .listening || state == .preparing
    }

    nonisolated static var supportedLocales: [Locale] {
        SFSpeechRecognizer.supportedLocales().sorted { $0.identifier < $1.identifier }
    }

    nonisolated static func merge(base: String, transcript: String) -> String {
        TranscriptAccumulator.join(base, transcript)
    }

    func toggle(localeIdentifier: String = "") async {
        if isBusy {
            stop()
        } else {
            await start(localeIdentifier: localeIdentifier)
        }
    }

    func start(localeIdentifier: String = "") async {
        guard !isBusy else { return }
        state = .preparing
        transcript = ""
        accumulator = TranscriptAccumulator()
        guard await SpeechSession.authorize() else { return finish(.denied) }
        guard state == .preparing else { return }
        let locale = localeIdentifier.isEmpty ? Locale.current : Locale(identifier: localeIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(), recognizer.isAvailable else { return finish(.unavailable) }
        generation += 1
        let current = generation
        let session = SpeechSession()
        do {
            try session.start(recognizer: recognizer) { [weak self] update in
                Task { @MainActor in self?.handle(update, generation: current) }
            }
            self.session = session
            state = .listening
        } catch {
            session.stop()
            finish(.failed)
        }
    }

    func stop() {
        finish(.idle)
    }

    private func handle(_ update: SpeechUpdate, generation current: Int) {
        guard current == generation, state == .listening else { return }
        if let text = update.text {
            accumulator.update(text)
            transcript = accumulator.text
        }
        if update.failed {
            finish(transcript.isEmpty ? .failed : .idle)
        } else if update.isFinal {
            finish(.idle)
        }
    }

    private func finish(_ next: SpeechState) {
        generation += 1
        session?.stop()
        session = nil
        state = next
    }
}
