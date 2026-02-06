import Foundation

enum DefaultDocumentService {
    static let baseURL = URL(string: "https://pass-signing-service-670044709036.europe-west1.run.app")!

    enum ServiceError: LocalizedError {
        case invalidResponse
        case unauthorized
        case notFound
        case server(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Unexpected server response."
            case .unauthorized:
                return "Invalid access code."
            case .notFound:
                return "Default document not found."
            case .server(let message):
                return message
            }
        }
    }

    static func download(kind: StoredDocumentKind, accessCode: String) async throws -> Data {
        let url = baseURL.appendingPathComponent("default-doc")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "code": accessCode,
            "doc": kind.rawValue
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        switch http.statusCode {
        case 200:
            if let signedURL = try? decodeSignedURL(from: data) {
                let (fileData, _) = try await URLSession.shared.data(from: signedURL)
                return fileData
            }
            return data
        case 401, 403:
            throw ServiceError.unauthorized
        case 404:
            throw ServiceError.notFound
        default:
            let message = decodeErrorMessage(from: data) ?? String(data: data, encoding: .utf8) ?? "Server error."
            throw ServiceError.server(message)
        }
    }

    private static func decodeSignedURL(from data: Data) throws -> URL {
        struct SignedResponse: Decodable {
            let url: String
        }
        let decoded = try JSONDecoder().decode(SignedResponse.self, from: data)
        guard let url = URL(string: decoded.url) else {
            throw ServiceError.invalidResponse
        }
        return url
    }

    private static func decodeErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let error: String
        }
        guard let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
            return nil
        }
        return decoded.error
    }
}
