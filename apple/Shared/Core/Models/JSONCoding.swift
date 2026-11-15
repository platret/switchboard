import Foundation

enum JSONCoding {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }()

    static func decode<Value: Decodable>(_ type: Value.Type, from text: String) throws -> Value {
        try decoder.decode(type, from: Data(text.utf8))
    }

    static func string<Value: Encodable>(_ value: Value) throws -> String {
        String(decoding: try encoder.encode(value), as: UTF8.self)
    }
}
