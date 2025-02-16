import Foundation
@testable import OpenAISwift

extension OpenAIClient {
    static func createMockClient(
        apiKey: String = "test-key",
        timeout: TimeInterval = 60,
        baseURL: String = "https://api.openai.com/v1",
        session: URLSession? = nil
    ) -> OpenAIClient {
        if session == nil {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)
            return OpenAIClient(apiKey: apiKey, timeout: timeout, baseURL: baseURL, session: mockSession)
        }
        return OpenAIClient(apiKey: apiKey, timeout: timeout, baseURL: baseURL, session: session)
    }
}

extension ChatRequest {
    static func mock(
        model: String = "gpt-4",
        messages: [Message] = [Message(role: "user", content: "Hello!")],
        temperature: Double? = nil
    ) -> ChatRequest {
        ChatRequest(
            model: model,
            messages: messages,
            temperature: temperature
        )
    }
}

extension ChatResponse {
    static func mock(
        id: String = "chatcmpl-123",
        model: String = "gpt-4",
        content: String = "Hello! How can I help you today?"
    ) -> ChatResponse {
        ChatResponse(
            id: id,
            object: "chat.completion",
            created: Int(Date().timeIntervalSince1970),
            model: model,
            choices: [
                ChatResponse.Choice(
                    index: 0,
                    message: Message(role: "assistant", content: content),
                    finishReason: "stop"
                )
            ],
            usage: ChatResponse.Usage(
                promptTokens: 10,
                completionTokens: 20,
                totalTokens: 30
            )
        )
    }
}

extension String {
    static func mockSuccessResponse(
        id: String = "chatcmpl-123",
        model: String = "gpt-4",
        content: String = "Hello! How can I help you today?"
    ) -> String {
        """
        {
            "id": "\(id)",
            "object": "chat.completion",
            "created": \(Int(Date().timeIntervalSince1970)),
            "model": "\(model)",
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": 20,
                "total_tokens": 30
            },
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": "\(content)"
                    },
                    "finish_reason": "stop",
                    "index": 0
                }
            ]
        }
        """
    }
    
    static func mockErrorResponse(
        message: String = "Invalid API key provided",
        type: String = "invalid_request_error",
        code: String = "invalid_api_key"
    ) -> String {
        """
        {
            "error": {
                "message": "\(message)",
                "type": "\(type)",
                "param": null,
                "code": "\(code)"
            }
        }
        """
    }
} 