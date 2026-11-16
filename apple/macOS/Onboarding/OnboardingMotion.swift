import SwiftUI

enum OnboardingMotion {
    static let step = Animation.spring(response: 0.55, dampingFraction: 0.88)
    static let settle = Animation.spring(response: 0.42, dampingFraction: 0.72)
    static let fade = Animation.easeInOut(duration: 0.2)
    static let stagger = 0.07

    static func step(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : step
    }
}
