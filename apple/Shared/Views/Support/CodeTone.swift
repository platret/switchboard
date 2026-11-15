import SwiftUI

enum CodeTone {
    case plain
    case removed
    case added

    var symbol: String? {
        switch self {
        case .plain: nil
        case .removed: "minus.circle"
        case .added: "plus.circle"
        }
    }

    var tint: Color? {
        switch self {
        case .plain: nil
        case .removed: Palette.danger
        case .added: Surface.added
        }
    }

    var fill: Color {
        tint?.opacity(0.10) ?? Surface.sunken
    }

    var stroke: Color {
        tint?.opacity(0.45) ?? Surface.hairline
    }
}
