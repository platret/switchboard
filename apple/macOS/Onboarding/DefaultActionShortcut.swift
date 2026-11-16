import SwiftUI

struct DefaultActionShortcut: ViewModifier {
    let isDefault: Bool

    func body(content: Content) -> some View {
        if isDefault {
            content.keyboardShortcut(.defaultAction)
        } else {
            content
        }
    }
}
