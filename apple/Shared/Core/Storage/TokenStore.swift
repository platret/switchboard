import Foundation

protocol TokenStore: AnyObject {
    func read() -> String?
    func save(_ token: String)
    func clear()
}

final class InMemoryTokenStore: TokenStore {
    private var token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func read() -> String? {
        token
    }

    func save(_ token: String) {
        self.token = token
    }

    func clear() {
        token = nil
    }
}
