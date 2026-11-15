import Foundation
#if os(iOS)
import UIKit
#endif

enum SystemSettings {
    static var privacyURL: URL? {
        #if os(macOS)
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        #else
        URL(string: UIApplication.openSettingsURLString)
        #endif
    }
}
