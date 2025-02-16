import XCTest
import Combine

@testable import OpenAISwift

final class OpenAIClientCombineTests: XCTestCase {
    var client: OpenAIClient!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        client = OpenAIClient.createMockClient()
        cancellables = []
    }
    
    override func tearDown() {
        client = nil
        cancellables = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func testSuccessfulChatCompletionPublisher() throws {
        let expectation = expectation(description: "Chat completion")
        let expectedContent = "Hello from Combine!"
        
        MockURLProtocol.requestHandler = { request in
            (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                String.mockSuccessResponse(content: expectedContent).data(using: .utf8)!
            )
        }
        
        var receivedResponse: ChatResponse?
        var receivedError: Error?
        
        let request = ChatRequest.mock()
        client.createChatCompletionPublisher(request)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
        
        XCTAssertNil(receivedError)
        XCTAssertNotNil(receivedResponse)
        XCTAssertEqual(receivedResponse?.choices.first?.message.content, expectedContent)
    }
    
    func testErrorChatCompletionPublisher() throws {
        let expectation = expectation(description: "Chat completion error")
        let errorMessage = "Test error message"
        
        MockURLProtocol.requestHandler = { request in
            (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                String.mockErrorResponse(message: errorMessage).data(using: .utf8)!
            )
        }
        
        var receivedResponse: ChatResponse?
        var receivedError: Error?
        
        let request = ChatRequest.mock()
        client.createChatCompletionPublisher(request)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
        
        XCTAssertNil(receivedResponse)
        XCTAssertNotNil(receivedError)
        
        if case let OpenAIError.apiError(code, message) = receivedError as? OpenAIError {
            XCTAssertEqual(code, 400)
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected API error")
        }
    }
    
    func testCancellation() throws {
        let expectation = expectation(description: "Publisher cancellation")
        var cancellable: AnyCancellable?
        
        MockURLProtocol.requestHandler = { request in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
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
        
        let request = ChatRequest.mock()
        cancellable = client.createChatCompletionPublisher(request)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
        
        // Cancel immediately
        cancellable?.cancel()
        
        waitForExpectations(timeout: 1)
    }
} 