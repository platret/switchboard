import Foundation

struct BundledHost: Hashable, Sendable {
    let root: URL

    init?(root: URL) {
        guard FileManager.default.fileExists(atPath: root.appending(path: "start").path) else { return nil }
        self.root = root
    }

    var start: URL {
        root.appending(path: "start")
    }

    var claude: URL {
        root.appending(path: "claude")
    }

    var roles: URL {
        root.appending(path: "app").appending(path: "roles.json")
    }

    static func find(in bundle: Bundle = .main) -> BundledHost? {
        bundle.resourceURL.flatMap { BundledHost(root: $0.appending(path: "Host")) }
    }
}
