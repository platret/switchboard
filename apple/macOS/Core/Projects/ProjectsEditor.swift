import Foundation
import Observation

@MainActor
@Observable
final class ProjectsEditor {
    var projects: [Project] = []
    private(set) var saved: [Project] = []
    private(set) var roles: [Role] = RoleCatalog.fallback
    private(set) var location: ProjectsLocation?
    private(set) var didLoad = false
    /// Set when projects.json exists but cannot be read. The list stays read-only so a save cannot replace the file.
    private(set) var readFailure: String?
    var failure: String?

    init(projects: [Project] = [], roles: [Role] = RoleCatalog.fallback, location: ProjectsLocation? = nil) {
        self.projects = projects
        saved = projects
        self.roles = roles
        self.location = location
        didLoad = location != nil
    }

    var isEditable: Bool {
        (location?.isEditable ?? false) && readFailure == nil
    }

    var hasChanges: Bool {
        projects != saved
    }

    var defaultRoles: [String] {
        let available = Set(roles.map(\.id))
        let preferred = ProjectsFile.defaultRoles.filter(available.contains)
        return preferred.isEmpty ? roles.prefix(1).map(\.id) : preferred
    }

    func load(_ location: ProjectsLocation?) async {
        self.location = location
        guard let location else {
            projects = []
            saved = []
            readFailure = nil
            didLoad = true
            return
        }
        let found = await Task.detached { () -> (Result<[Project]?, Error>, [Role]) in
            (Result { try ProjectsFile.load(location.file) }, RoleCatalog.load(from: location.roleFiles))
        }.value
        switch found.0 {
        case .success(let list):
            projects = list ?? []
            readFailure = nil
        case .failure:
            projects = []
            readFailure = "Switchboard could not read \(SwitchboardHome.displayPath(location.file.path)). Fix or remove that file, then reload. Switchboard leaves it as it is."
        }
        saved = projects
        roles = found.1
        failure = nil
        didLoad = true
    }

    func add(_ folders: [URL]) {
        guard isEditable else { return }
        projects = ProjectsFile.adding(folders, to: projects, roles: defaultRoles)
    }

    func remove(_ project: Project) {
        projects.removeAll { $0.id == project.id }
    }

    func rename(_ project: Project, to name: String) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].name = name
    }

    func toggle(role: String, in project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        var agents = projects[index].agents
        if let existing = agents.firstIndex(of: role) {
            guard agents.count > 1 else { return }
            agents.remove(at: existing)
        } else {
            agents.append(role)
        }
        projects[index].agents = agents
    }

    @discardableResult
    func save() async -> Bool {
        guard let location, isEditable, hasChanges else { return false }
        let cleaned = projects.map { project in
            var project = project
            let trimmed = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
            project.name = trimmed.isEmpty ? ProjectsFile.displayName(for: URL(fileURLWithPath: ProjectsFile.expanded(project.path))) : trimmed
            return project
        }
        do {
            try await Task.detached { try ProjectsFile.write(cleaned, to: location.file) }.value
            projects = cleaned
            saved = cleaned
            failure = nil
            return true
        } catch {
            failure = "Switchboard could not save \(SwitchboardHome.displayPath(location.file.path)). \(error.localizedDescription)"
            return false
        }
    }
}
