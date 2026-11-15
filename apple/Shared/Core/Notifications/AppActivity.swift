import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum AppActivity {
    @MainActor
    static func isActive() -> Bool {
        #if os(macOS)
        NSApplication.shared.isActive
        #else
        UIApplication.shared.applicationState == .active
        #endif
    }
}
