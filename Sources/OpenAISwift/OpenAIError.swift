import Foundation

public enum OpenAIError: Error, LocalizedError {
    case invalidURL
    case apiError(code: Int, message: String)
    case decodingError
    case timeout
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

struct ErrorResponse: Codable {
    struct ErrorDetail: Codable {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }
    
    let error: ErrorDetail
} 