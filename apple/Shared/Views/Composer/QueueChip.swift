import SwiftUI

struct QueueChip: View {
    let message: QueuedMessage
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock").font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(message.text).font(.footnote).lineLimit(1).frame(maxWidth: 220, alignment: .leading)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.caption2.weight(.bold)).padding(4).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Remove queued message: \(message.text)")
            .help("Remove from the queue")
        }
        .padding(.leading, 10)
        .padding(.trailing, 5)
        .padding(.vertical, 4)
        .background(Surface.sunken, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Queued: \(message.text)")
    }
}
