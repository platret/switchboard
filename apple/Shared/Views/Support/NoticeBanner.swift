import SwiftUI

struct NoticeBanner: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if let notice = store.notice {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.amber).accessibilityHidden(true)
                Text(notice).font(.callout).frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    store.dismissNotice()
                } label: {
                    Image(systemName: "xmark").font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Dismiss message")
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Surface.corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Surface.corner, style: .continuous).strokeBorder(Surface.hairline))
            .task(id: notice) {
                try? await Task.sleep(for: .seconds(7))
                if !Task.isCancelled { store.dismissNotice() }
            }
        }
    }
}
