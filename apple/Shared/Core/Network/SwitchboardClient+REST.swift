import Foundation

extension SwitchboardClient {
    private struct CreateBody: Encodable {
        let projectId: String
        let role: String
        let name: String
    }

    private struct RenameBody: Encodable {
        let name: String
    }

    private struct ErrorBody: Decodable {
        let error: String
    }

    func createAgent(projectId: String, role: String, name: String) async throws -> Agent {
        let body = try JSONCoding.encoder.encode(CreateBody(projectId: projectId, role: role, name: name))
        return try await decodeAgent(from: perform("POST", "agents", body: body))
    }

    func renameAgent(id: String, name: String) async throws -> Agent {
        let body = try JSONCoding.encoder.encode(RenameBody(name: name))
        return try await decodeAgent(from: perform("PATCH", "agents/\(id)", body: body))
    }

    func deleteAgent(id: String) async throws {
        _ = try await perform("DELETE", "agents/\(id)", body: nil)
    }

    private func decodeAgent(from data: Data) throws -> Agent {
        guard let agent = try? JSONCoding.decoder.decode(Agent.self, from: data) else { throw ClientError.unexpectedResponse }
        return agent
    }

    private func perform(_ method: String, _ path: String, body: Data?) async throws -> Data {
        guard let endpoint, let token else { throw ClientError.notConfigured }
        var request = URLRequest(url: endpoint.apiURL(path), timeoutInterval: 15)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.unexpectedResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONCoding.decoder.decode(ErrorBody.self, from: data))?.error
            throw ClientError.server(message ?? "The host answered with status \(http.statusCode).")
        }
        return data
    }
}
