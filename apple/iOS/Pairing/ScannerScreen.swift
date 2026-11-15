import SwiftUI
import UIKit

struct ScannerScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var scanner = QRScanner()
    @State private var wasRejected = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan pairing code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .task {
            scanner.onCode = handle
            await scanner.start()
        }
        .onDisappear { scanner.stop() }
    }

    @ViewBuilder private var content: some View {
        switch scanner.state {
        case .preparing:
            ProgressView("Starting the camera")
        case .scanning:
            CameraPreview(session: scanner.session)
                .ignoresSafeArea(edges: .bottom)
                .overlay { ScannerOverlay(wasRejected: wasRejected) }
        case .denied, .unavailable:
            ScannerFallback(state: scanner.state, wasRejected: wasRejected, onPaste: handle)
        }
    }

    private func handle(_ code: String) {
        guard let link = PairingLink(string: code) else {
            wasRejected = true
            return
        }
        scanner.stop()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        store.pair(with: link)
        dismiss()
    }
}
