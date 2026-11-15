import Foundation

private struct Lossy<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

extension KeyedDecodingContainer {
    func lossyArray<Value: Decodable>(_ type: Value.Type, forKey key: Key) throws -> [Value] {
        let entries = try decodeIfPresent([Lossy<Value>].self, forKey: key) ?? []
        return entries.compactMap(\.value)
    }
}
