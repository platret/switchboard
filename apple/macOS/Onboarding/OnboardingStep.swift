import Foundation

enum OnboardingStep: Int, CaseIterable, Comparable, Sendable {
    case welcome
    case checks
    case projects
    case host
    case phone
    case done

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .checks: "Check your Mac"
        case .projects: "Choose projects"
        case .host: "Start the host"
        case .phone: "Your iPhone"
        case .done: "Done"
        }
    }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }

    static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
