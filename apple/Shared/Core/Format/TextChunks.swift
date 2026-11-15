import Foundation

enum TextChunks {
    static func split(_ text: String, limit: Int) -> [String] {
        var chunks: [String] = []
        var rest = Substring(text)
        while let end = rest.index(rest.startIndex, offsetBy: limit, limitedBy: rest.endIndex), end < rest.endIndex {
            if let lineEnd = rest[..<end].lastIndex(where: \.isNewline) {
                chunks.append(String(rest[..<lineEnd]))
                rest = rest[rest.index(after: lineEnd)...]
            } else {
                chunks.append(String(rest[..<end]))
                rest = rest[end...]
            }
        }
        chunks.append(String(rest))
        return chunks
    }
}
