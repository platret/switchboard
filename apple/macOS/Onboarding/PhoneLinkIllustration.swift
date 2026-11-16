import SwiftUI

struct PhoneLinkIllustration: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "iphone").font(.system(size: 34, weight: .light))
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle().frame(width: 4, height: 4).opacity(0.5)
                }
            }
            Image(systemName: "lock.shield").font(.system(size: 22)).foregroundStyle(Palette.cobalt)
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle().frame(width: 4, height: 4).opacity(0.5)
                }
            }
            Image(systemName: "laptopcomputer").font(.system(size: 34, weight: .light))
        }
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }
}
