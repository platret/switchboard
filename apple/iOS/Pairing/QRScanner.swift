@preconcurrency import AVFoundation
import Observation

@MainActor
@Observable
final class QRScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private(set) var state: ScannerState = .preparing

    @ObservationIgnored var onCode: ((String) -> Void)?
    @ObservationIgnored let session = AVCaptureSession()
    @ObservationIgnored private let queue = DispatchQueue(label: "ch.platret.switchboard.scanner")
    @ObservationIgnored private var isConfigured = false

    func start() async {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            state = .unavailable
            return
        }
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            state = .denied
            return
        }
        guard configure(camera) else {
            state = .unavailable
            return
        }
        state = .scanning
        let session = session
        queue.async {
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        let session = session
        queue.async {
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configure(_ camera: AVCaptureDevice) -> Bool {
        if isConfigured { return true }
        guard let input = try? AVCaptureDeviceInput(device: camera) else { return false }
        let output = AVCaptureMetadataOutput()
        guard session.canAddInput(input), session.canAddOutput(output) else { return false }
        session.beginConfiguration()
        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
        guard output.availableMetadataObjectTypes.contains(.qr) else { return false }
        output.metadataObjectTypes = [.qr]
        output.setMetadataObjectsDelegate(self, queue: .main)
        isConfigured = true
        return true
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let codes = objects.compactMap { ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }
        guard let code = codes.first else { return }
        Task { @MainActor in self.onCode?(code) }
    }
}
