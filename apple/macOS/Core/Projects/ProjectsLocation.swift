import Foundation

struct ProjectsLocation: Hashable, Sendable {
    let file: URL
    let roleFiles: [URL]
    let isEditable: Bool

    init(file: URL, roleFiles: [URL], isEditable: Bool) {
        self.file = file
        self.roleFiles = roleFiles
        self.isEditable = isEditable
    }

    init?(source: HostSource?) {
        switch source {
        case .bundled(let host, let home)?:
            self.init(file: home.appending(path: SwitchboardHome.projectsName), roleFiles: [home.appending(path: SwitchboardHome.rolesName), host.roles], isEditable: true)
        case .repo(let folder)?:
            let root = URL(fileURLWithPath: (folder as NSString).expandingTildeInPath)
            self.init(file: root.appending(path: SwitchboardHome.projectsName), roleFiles: [root.appending(path: SwitchboardHome.rolesName)], isEditable: false)
        case nil:
            return nil
        }
    }
}
