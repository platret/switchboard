import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ComposerKeys: ViewModifier {
    let onSend: () -> Void

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .onSubmit(onSend)
            .onKeyPress(.return, phases: .down) { press in
                guard press.modifiers.contains(.shift) else { return .ignored }
                NSApp.sendAction(#selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)), to: nil, from: nil)
                return .handled
            }
        #else
        content
        #endif
    }
}
