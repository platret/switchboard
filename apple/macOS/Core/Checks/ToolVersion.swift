import Foundation

struct ToolVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    static let nodeMinimum = ToolVersion(major: 22, minor: 12, patch: 0)

    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init?(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.hasPrefix("v") ? trimmed.dropFirst() : Substring(trimmed)
        let parts = digits.split(separator: "-").first?.split(separator: ".").map { Int($0) } ?? []
        guard let major = parts.first ?? nil else { return nil }
        let minor = parts.count > 1 ? parts[1] : 0
        let patch = parts.count > 2 ? parts[2] : 0
        guard let minor, let patch else { return nil }
        self.init(major: major, minor: minor, patch: patch)
    }

    var description: String {
        "\(major).\(minor).\(patch)"
    }

    static func < (lhs: ToolVersion, rhs: ToolVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
