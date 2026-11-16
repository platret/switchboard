import Foundation

enum RoleCatalog {
    static let fallback = [
        Role(id: "dev", name: "Developer"),
        Role(id: "tester", name: "Tester"),
        Role(id: "reviewer", name: "Reviewer"),
        Role(id: "ideation", name: "Ideation"),
        Role(id: "deploy-check", name: "Deploy check"),
        Role(id: "tutor", name: "Tutor"),
        Role(id: "social", name: "Social media"),
    ]

    static func load(from files: [URL]) -> [Role] {
        for file in files {
            guard let data = try? Data(contentsOf: file), let roles = try? JSONDecoder().decode([Role].self, from: data), !roles.isEmpty else { continue }
            return roles
        }
        return fallback
    }
}
