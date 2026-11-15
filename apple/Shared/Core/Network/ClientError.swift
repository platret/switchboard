import Foundation

enum ClientError: LocalizedError, Hashable {
    case notConfigured
    case invalidHost
    case missingToken
    case notConnected
    case notDelivered
    case server(String)
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Switchboard is not connected to a host yet."
        case .invalidHost: "That host address is not valid. Use something like http://100.64.0.1:4317."
        case .missingToken: "Enter the access token from the host."
        case .notConnected: "Not connected to the host. The message was not sent."
        case .notDelivered: "A message may not have reached the host. Check the chat and send it again if it is missing."
        case .server(let message): message
        case .unexpectedResponse: "The host sent an answer Switchboard could not read."
        }
    }
}
