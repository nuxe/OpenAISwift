import Foundation

/// Errors that can occur when using the OpenAI API.
///
/// This enum provides strongly-typed errors for common failure cases when
/// interacting with the OpenAI API, along with localized descriptions for each error.
///
/// Example usage:
/// ```swift
/// do {
///     let response = try await client.sendMessage("Hello")
/// } catch let error as OpenAIError {
///     switch error {
///     case .apiError(let code, let message):
///         print("API Error \(code): \(message)")
///     case .invalidURL:
///         print("Invalid URL")
///     case .decodingError:
///         print("Failed to decode response")
///     case .timeout:
///         print("Request timed out")
///     case .unknown(let error):
///         print("Unknown error: \(error)")
///     }
/// }
/// ```
public enum OpenAIError: Error, LocalizedError {
    /// The URL for the API request was invalid
    case invalidURL
    
    /// The API returned an error response
    /// - Parameters:
    ///   - code: The HTTP status code
    ///   - message: The error message from the API
    case apiError(code: Int, message: String)
    
    /// Failed to decode the API response into the expected type
    case decodingError
    
    /// The request timed out
    case timeout
    
    /// An unknown error occurred
    /// - Parameter error: The underlying error
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL or endpoint"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .decodingError:
            return "Failed to decode API response"
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

/// Internal type for decoding error responses from the API.
///
/// This type matches the error response format from OpenAI's API:
/// ```json
/// {
///     "error": {
///         "message": "The error message",
///         "type": "invalid_request_error",
///         "param": "model",
///         "code": "model_not_found"
///     }
/// }
/// ```
struct ErrorResponse: Codable {
    /// Details about the error from the API
    struct ErrorDetail: Codable {
        /// The error message
        let message: String
        
        /// The type of error (e.g., "invalid_request_error")
        let type: String?
        
        /// The parameter that caused the error, if any
        let param: String?
        
        /// A specific error code from the API
        let code: String?
    }
    
    /// The error details
    let error: ErrorDetail
} 