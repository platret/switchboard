import Foundation

enum ClaudeCLI {
    static let scriptName = "Switchboard Claude sign-in.command"

    static func candidates(home: URL) -> [String] {
        [
            home.appending(path: ".local/bin/claude").path,
            home.appending(path: ".claude/local/claude").path,
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
    }

    static func locate(home: URL, bundled: BundledHost?, isExecutable: (String) -> Bool = FileManager.default.isExecutableFile(atPath:)) -> String? {
        let paths = candidates(home: home) + [bundled?.claude.path].compactMap { $0 }
        return paths.first(where: isExecutable)
    }

    static func signInScript(claude: String) -> String {
        let quoted = "'" + claude.replacingOccurrences(of: "'", with: "'\\''") + "'"
        return """
        #!/bin/zsh
        cd ~
        clear
        print "Sign in to Claude Code for Switchboard"
        print ""
        print "Type /login and press Return, then finish in your browser."
        print "When it says you are signed in, close this window and go back to Switchboard."
        print ""
        exec \(quoted)

        """
    }

    static func writeSignInScript(claude: String, folder: URL = URL(fileURLWithPath: NSTemporaryDirectory())) throws -> URL {
        let file = folder.appending(path: scriptName)
        try Data(signInScript(claude: claude).utf8).write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
        return file
    }
}
