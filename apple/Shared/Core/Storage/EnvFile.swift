import Foundation

enum EnvFile {
    static let tokenKey = "SWITCHBOARD_TOKEN"
    static let portKey = "SWITCHBOARD_PORT"

    static func parse(_ text: String) -> [String: String] {
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), let separator = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[..<separator].trimmingCharacters(in: .whitespaces)
            let value = trimmed[trimmed.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { values[key] = unquote(value) }
        }
        return values
    }

    static func values(inFolder folder: String) -> [String: String] {
        guard !folder.trimmingCharacters(in: .whitespaces).isEmpty else { return [:] }
        let path = (folder as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: path).appending(path: ".env")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        return parse(text)
    }

    static func token(inFolder folder: String) -> String? {
        guard let token = values(inFolder: folder)[tokenKey], !token.isEmpty else { return nil }
        return token
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2, let first = value.first, first == value.last, first == "\"" || first == "'" else { return value }
        return String(value.dropFirst().dropLast())
    }
}
