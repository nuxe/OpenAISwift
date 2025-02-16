import Foundation
import Combine

/// A client for interacting with OpenAI's API services.
///
/// The `OpenAIClient` provides a modern Swift interface to OpenAI's APIs, supporting both async/await
/// and Combine workflows. It handles authentication, request creation, and response parsing.
///
/// Example usage:
/// ```swift
/// let client = OpenAIClient(apiKey: "your-api-key")
///
/// // Using async/await
/// do {
///     let response = try await client.sendMessage("Hello, how are you?")
///     print(response)
/// } catch {
///     print("Error: \(error)")
/// }
/// ```
public final class OpenAIClient {
    private let session: URLSession
    private let apiKey: String
    private let timeout: TimeInterval
    private let baseURL = "https://api.openai.com/v1"
    
    /// Creates a new OpenAI API client.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key. You can find this in your OpenAI dashboard.
    ///   - timeout: The timeout interval for requests in seconds. Defaults to 60 seconds.
    ///
    /// - Note: The client will configure a URLSession with the specified timeout for both
    ///         the request and resource timeouts.
    public init(apiKey: String, timeout: TimeInterval = 60) {
        self.apiKey = apiKey
        self.timeout = timeout
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)
    }
    
    /// Creates a URLRequest for an OpenAI API endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint path (e.g., "chat/completions")
    ///   - method: The HTTP method to use. Defaults to "POST"
    ///   - body: The request body to encode
    ///
    /// - Returns: A configured URLRequest
    /// - Throws: `OpenAIError.invalidURL` if the URL cannot be constructed
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
    
    /// Sends a request to the OpenAI API and decodes the response.
    ///
    /// - Parameter request: The URLRequest to send
    /// - Returns: The decoded response of type `T`
    /// - Throws:
    ///   - `OpenAIError.invalidURL` if the response is not an HTTP response
    ///   - `OpenAIError.apiError` if the server returns an error
    ///   - `OpenAIError.decodingError` if the response cannot be decoded
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