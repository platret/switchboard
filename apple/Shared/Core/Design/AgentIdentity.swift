import SwiftUI

enum AgentIdentity {
    static func monogram(for name: String) -> String {
        let words = name.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let letters = words.prefix(2).compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }

    static func hue(for id: String) -> Double {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return Double(hash % 360) / 360
    }

    static func color(for id: String) -> Color {
        Color(hue: hue(for: id), saturation: 0.52, brightness: 0.68)
    }
}
