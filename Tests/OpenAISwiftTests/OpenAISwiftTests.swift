import XCTest
@testable import OpenAISwift

final class OpenAISwiftTests: XCTestCase {
    var client: OpenAIClient!
    let mockAPIKey = "mock-api-key"
    
    override func setUp() {
        super.setUp()
        client = OpenAIClient(apiKey: mockAPIKey)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    // MARK: - Model Tests
    
    func testChatRequestEncoding() throws {
        let messages = [
            Message(role: "system", content: "You are a helpful assistant"),
            Message(role: "user", content: "Hello!")
        ]
        
        let request = ChatRequest(
            model: "gpt-4",
            messages: messages,
            temperature: 0.7,
            maxTokens: 150,
            user: "test-user"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["model"] as? String, "gpt-4")
        XCTAssertEqual((json?["messages"] as? [[String: Any]])?.count, 2)
        XCTAssertEqual(json?["temperature"] as? Double, 0.7)
        XCTAssertEqual(json?["max_tokens"] as? Int, 150)
        XCTAssertEqual(json?["user"] as? String, "test-user")
    }
    
    func testMessageEncoding() throws {
        let message = Message(role: "user", content: "Hello!", name: "John")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["role"] as? String, "user")
        XCTAssertEqual(json?["content"] as? String, "Hello!")
        XCTAssertEqual(json?["name"] as? String, "John")
    }
    
    func testChatResponseDecoding() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677858242,
            "model": "gpt-4",
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": 20,
                "total_tokens": 30
            },
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": "Hello! How can I help you today?"
                    },
                    "finish_reason": "stop",
                    "index": 0
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ChatResponse.self, from: data)
        
        XCTAssertEqual(response.id, "chatcmpl-123")
        XCTAssertEqual(response.object, "chat.completion")
        XCTAssertEqual(response.created, 1677858242)
        XCTAssertEqual(response.model, "gpt-4")
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.role, "assistant")
        XCTAssertEqual(response.choices[0].message.content, "Hello! How can I help you today?")
        XCTAssertEqual(response.choices[0].finishReason, "stop")
        XCTAssertEqual(response.usage.promptTokens, 10)
        XCTAssertEqual(response.usage.completionTokens, 20)
        XCTAssertEqual(response.usage.totalTokens, 30)
    }
    
    // MARK: - Error Tests
    
    func testErrorDescriptions() {
        let invalidURLError = OpenAIError.invalidURL
        XCTAssertEqual(invalidURLError.errorDescription, "Invalid URL or endpoint")
        
        let apiError = OpenAIError.apiError(code: 404, message: "Model not found")
        XCTAssertEqual(apiError.errorDescription, "API Error (404): Model not found")
        
        let decodingError = OpenAIError.decodingError
        XCTAssertEqual(decodingError.errorDescription, "Failed to decode API response")
        
        let timeoutError = OpenAIError.timeout
        XCTAssertEqual(timeoutError.errorDescription, "Request timed out")
        
        let underlyingError = NSError(domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let unknownError = OpenAIError.unknown(underlyingError)
        XCTAssertEqual(unknownError.errorDescription, "Unknown error: Test error")
    }
    
    func testErrorResponseDecoding() throws {
        let json = """
        {
            "error": {
                "message": "Invalid API key",
                "type": "invalid_request_error",
                "param": "api_key",
                "code": "invalid_api_key"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
        
        XCTAssertEqual(errorResponse.error.message, "Invalid API key")
        XCTAssertEqual(errorResponse.error.type, "invalid_request_error")
        XCTAssertEqual(errorResponse.error.param, "api_key")
        XCTAssertEqual(errorResponse.error.code, "invalid_api_key")
    }
    
    // MARK: - Request Creation Tests
    
    func testRequestCreation() throws {
        let messages = [Message(role: "user", content: "Hello")]
        let chatRequest = ChatRequest(model: "gpt-4", messages: messages)
        
        let request = try client.createRequest(endpoint: "chat/completions", body: chatRequest)
        
        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(mockAPIKey)")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        let requestBody = try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
        XCTAssertEqual(requestBody?["model"] as? String, "gpt-4")
        XCTAssertNotNil(requestBody?["messages"])
    }
    
    // MARK: - Integration Tests
    
    func testClientInitialization() {
        let customTimeout: TimeInterval = 120
        let client = OpenAIClient(apiKey: mockAPIKey, timeout: customTimeout)
        XCTAssertNotNil(client)
    }
}
