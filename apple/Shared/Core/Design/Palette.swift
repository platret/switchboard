import SwiftUI

enum Palette {
    static let cobalt = Color("AccentColor")
    static let amber = Color("Amber")
    static let danger = Color("Danger")
    static let idle = Color.secondary

    static func lamp(_ status: AgentStatus) -> Color {
        switch status {
        case .idle: idle
        case .working: cobalt
        case .waiting: amber
        case .error: danger
        }
    }
}
