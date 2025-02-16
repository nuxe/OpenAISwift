import XCTest
import Foundation
@testable import OpenAISwift

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

final class OpenAIClientNetworkTests: XCTestCase {
    var client: OpenAIClient!
    
    override func setUp() {
        super.setUp()
        client = OpenAIClient.createMockClient()
    }
    
    override func tearDown() {
        client = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func testSuccessfulChatCompletion() async throws {
        let expectedContent = "Hello! I'm here to help."
        let jsonResponse = String.mockSuccessResponse(content: expectedContent)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonResponse.data(using: .utf8)!)
        }
        
        let request = ChatRequest.mock()
        let response = try await client.createChatCompletion(request)
        
        XCTAssertEqual(response.choices.first?.message.content, expectedContent)
        XCTAssertEqual(response.model, "gpt-4")
    }
    
    func testAPIError() async {
        let errorMessage = "Rate limit exceeded"
        let errorResponse = String.mockErrorResponse(
            message: errorMessage,
            type: "rate_limit_error",
            code: "rate_limit_exceeded"
        )
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, errorResponse.data(using: .utf8)!)
        }
        
        let request = ChatRequest.mock()
        
        do {
            _ = try await client.createChatCompletion(request)
            XCTFail("Expected error to be thrown")
        } catch let error as OpenAIError {
            switch error {
            case .apiError(let code, let message):
                XCTAssertEqual(code, 429)
                XCTAssertEqual(message, errorMessage)
            default:
                XCTFail("Expected API error")
            }
        } catch {
            XCTFail("Expected OpenAIError")
        }
    }
    
    func testInvalidURL() async {
        client = OpenAIClient.createMockClient(baseURL: "invalid-url")
        let request = ChatRequest.mock()
        
        do {
            _ = try await client.createChatCompletion(request)
            XCTFail("Expected error to be thrown")
        } catch OpenAIError.invalidURL {
            // Success
        } catch {
            XCTFail("Expected invalidURL error")
        }
    }
    
    func testDecodingError() async {
        let invalidResponse = "invalid json"
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, invalidResponse.data(using: .utf8)!)
        }
        
        let request = ChatRequest.mock()
        
        do {
            _ = try await client.createChatCompletion(request)
            XCTFail("Expected error to be thrown")
        } catch OpenAIError.decodingError {
            // Success
        } catch {
            XCTFail("Expected decodingError")
        }
    }
    
    func testRequestHeaders() async throws {
        var capturedRequest: URLRequest?
        
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                String.mockSuccessResponse().data(using: .utf8)!
            )
        }
        
        let request = ChatRequest.mock()
        _ = try await client.createChatCompletion(request)
        
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }
    
    func testRequestBody() async throws {
        var capturedBody: [String: Any]?
        
        MockURLProtocol.requestHandler = { request in
            if let data = request.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                String.mockSuccessResponse().data(using: .utf8)!
            )
        }
        
        let messages = [Message(role: "user", content: "Test message")]
        let request = ChatRequest.mock(messages: messages, temperature: 0.8)
        _ = try await client.createChatCompletion(request)
        
        XCTAssertEqual(capturedBody?["model"] as? String, "gpt-4")
        XCTAssertEqual(capturedBody?["temperature"] as? Double, 0.8)
        
        let capturedMessages = capturedBody?["messages"] as? [[String: Any]]
        XCTAssertEqual(capturedMessages?.count, 1)
        XCTAssertEqual(capturedMessages?.first?["role"] as? String, "user")
        XCTAssertEqual(capturedMessages?.first?["content"] as? String, "Test message")
    }
} 