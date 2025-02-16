import Foundation
import Combine

extension OpenAIClient {
    public func createChatCompletion(_ request: ChatRequest) async throws -> ChatResponse {
        let urlRequest = try createRequest(endpoint: "chat/completions", body: request)
        return try await send(urlRequest)
    }
    
    public func createChatCompletionPublisher(_ request: ChatRequest) -> AnyPublisher<ChatResponse, Error> {
        let task = Task { [weak self] in
            guard let self = self else {
                throw OpenAIError.unknown(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client deallocated"]))
            }
            return try await self.createChatCompletion(request)
        }
        
        return Future { promise in
            Task {
                do {
                    let response = try await task.value
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Convenience method for simple chat completions
    public func sendMessage(
        _ content: String,
        model: String = "gpt-4",
        systemPrompt: String? = nil
    ) async throws -> String {
        var messages: [Message] = []
        
        if let systemPrompt = systemPrompt {
            messages.append(Message(role: "system", content: systemPrompt))
        }
        
        messages.append(Message(role: "user", content: content))
        
        let request = ChatRequest(
            model: model,
            messages: messages
        )
        
        let response = try await createChatCompletion(request)
        return response.choices.first?.message.content ?? ""
    }
} 