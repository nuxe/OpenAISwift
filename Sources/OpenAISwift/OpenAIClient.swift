import Foundation
import Combine

public final class OpenAIClient {
    private let session: URLSession
    private let apiKey: String
    private let timeout: TimeInterval
    private let baseURL = "https://api.openai.com/v1"
    
    public init(apiKey: String, timeout: TimeInterval = 60) {
        self.apiKey = apiKey
        self.timeout = timeout
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)
    }
    
    internal func createRequest<T: Encodable>(
        endpoint: String,
        method: String = "POST",
        body: T
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        return request
    }
    
    internal func send<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidURL
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenAIError.apiError(
                code: httpResponse.statusCode,
                message: errorBody?.error.message ?? "Unknown error"
            )
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw OpenAIError.decodingError
        }
    }
} 