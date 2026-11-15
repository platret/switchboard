import SwiftUI

struct CopyButton: View {
    let text: String
    var label = "Copy"

    @State private var didCopy = false

    var body: some View {
        Button {
            Clipboard.copy(text)
            didCopy = true
        } label: {
            Label(didCopy ? "Copied" : label, systemImage: didCopy ? "checkmark" : "doc.on.doc")
                .font(.caption)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .accessibilityLabel(didCopy ? "Copied" : label)
        .task(id: didCopy) {
            guard didCopy else { return }
            try? await Task.sleep(for: .seconds(1.6))
            didCopy = false
        }
    }
}
