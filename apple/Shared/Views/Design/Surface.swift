import SwiftUI

enum Surface {
    static let sunken = Color.primary.opacity(0.06)
    static let hairline = Color.primary.opacity(0.12)
    static let added = Color.green
    static let corner: CGFloat = 10
    static let readingWidth: CGFloat = 780

    static var buttonCorner: CGFloat {
        #if os(macOS)
        7
        #else
        20
        #endif
    }

    static var buttonInset: CGFloat {
        #if os(macOS)
        5
        #else
        9
        #endif
    }

    static var code: Font {
        #if os(macOS)
        .callout.monospaced()
        #else
        .footnote.monospaced()
        #endif
    }

    static func onAccent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : .white
    }
}
