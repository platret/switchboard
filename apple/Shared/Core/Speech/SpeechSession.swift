import AVFoundation
import Speech

final class SpeechSession: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var observers: [NSObjectProtocol] = []

    static func authorize() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speech else { return false }
        return await AVCaptureDevice.requestAccess(for: .audio)
    }

    func start(recognizer: SFSpeechRecognizer, onUpdate: @escaping @Sendable (SpeechUpdate) -> Void) throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request.addsPunctuation = true
        try activateAudio()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw SpeechError.noMicrophone }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        try engine.start()
        observeInterruptions(onUpdate)
        self.request = request
        task = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                onUpdate(SpeechUpdate(text: result.bestTranscription.formattedString, isFinal: result.isFinal, failed: false))
            } else if error != nil {
                onUpdate(SpeechUpdate(text: nil, isFinal: true, failed: true))
            }
        }
    }

    func stop() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        deactivateAudio()
    }

    private func observeInterruptions(_ onUpdate: @escaping @Sendable (SpeechUpdate) -> Void) {
        let center = NotificationCenter.default
        let ended = SpeechUpdate(text: nil, isFinal: true, failed: false)
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil) { [weak engine] _ in
            if engine?.isRunning != true { onUpdate(ended) }
        })
        #if os(iOS)
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { note in
            let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if type == AVAudioSession.InterruptionType.began.rawValue { onUpdate(ended) }
        })
        #endif
    }

    private func activateAudio() throws {
        #if os(iOS)
        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audio.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
    }

    private func deactivateAudio() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}
