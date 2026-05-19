import Foundation

enum CBORGUsageClientError: LocalizedError {
    case badURL
    case emptyKey
    case badStatus(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The CBORG endpoint URL is invalid."
        case .emptyKey:
            return "No CBORG API key is saved."
        case .badStatus(let code, let body):
            return "CBORG returned HTTP \(code): \(body)"
        case .invalidResponse:
            return "CBORG returned an invalid response."
        }
    }
}

struct CBORGUsageClient {
    var endpoint: String

    func fetch(
        apiKey: String,
        preferredKeyAlias: String?,
        thresholdPercent: Double
    ) async throws -> CBORGUsageSnapshot {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw CBORGUsageClientError.emptyKey
        }
        guard let url = URL(string: endpoint) else {
            throw CBORGUsageClientError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CBORGUsageMonitor/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CBORGUsageClientError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw CBORGUsageClientError.badStatus(httpResponse.statusCode, String(body.prefix(500)))
        }

        let decoded = try JSONDecoder().decode(CBORGUserInfoResponse.self, from: data)
        return decoded.snapshot(
            preferredKeyAlias: preferredKeyAlias?.isEmpty == true ? nil : preferredKeyAlias,
            thresholdPercent: thresholdPercent
        )
    }
}
