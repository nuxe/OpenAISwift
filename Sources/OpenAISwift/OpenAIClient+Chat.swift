import Foundation
import Combine

/// Chat completion functionality for the OpenAI API client.
extension OpenAIClient {
    /// Creates a chat completion using OpenAI's chat API.
    ///
    /// This method sends a chat completion request to OpenAI's API and returns the response.
    /// It supports all parameters available in the API through the `ChatRequest` type.
    ///
    /// Example usage:
    /// ```swift
    /// let request = ChatRequest(
    ///     model: "gpt-4",
    ///     messages: [
    ///         Message(role: "system", content: "You are a helpful assistant"),
    ///         Message(role: "user", content: "What is Swift?")
    ///     ],
    ///     temperature: 0.7
    /// )
    ///
    /// do {
    ///     let response = try await client.createChatCompletion(request)
    ///     print(response.choices.first?.message.content ?? "")
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// - Parameter request: The chat completion request configuration
    /// - Returns: The chat completion response from the API
    /// - Throws: An `OpenAIError` if the request fails
    public func createChatCompletion(_ request: ChatRequest) async throws -> ChatResponse {
        let urlRequest = try createRequest(endpoint: "chat/completions", body: request)
        return try await send(urlRequest)
    }
    
    /// Creates a Combine publisher for a chat completion request.
    ///
    /// This method provides a reactive way to interact with OpenAI's chat API using Combine.
    /// The publisher will emit a single value upon success or complete with an error if the request fails.
    ///
    /// Example usage:
    /// ```swift
    /// let request = ChatRequest(
    ///     model: "gpt-4",
    ///     messages: [Message(role: "user", content: "Hello!")]
    /// )
    ///
    /// let cancellable = client.createChatCompletionPublisher(request)
    ///     .sink(
    ///         receiveCompletion: { completion in
    ///             if case .failure(let error) = completion {
    ///                 print("Error: \(error)")
    ///             }
    ///         },
    ///         receiveValue: { response in
    ///             print(response.choices.first?.message.content ?? "")
    ///         }
    ///     )
    /// ```
    ///
    /// - Parameter request: The chat completion request configuration
    /// - Returns: A publisher that emits the chat completion response or an error
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
    
    /// Sends a simple message to the chat API and returns the response text.
    ///
    /// This is a convenience method that simplifies the process of sending a single message
    /// to the chat API. It automatically constructs the appropriate request structure and
    /// extracts the response text.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let response = try await client.sendMessage(
    ///         "What is the capital of France?",
    ///         model: "gpt-4",
    ///         systemPrompt: "You are a geography expert"
    ///     )
    ///     print(response) // "The capital of France is Paris."
    /// } catch {
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - content: The message to send to the chat API
    ///   - model: The model to use (defaults to "gpt-4")
    ///   - systemPrompt: An optional system message to set the behavior of the assistant
    /// - Returns: The response text from the assistant
    /// - Throws: An `OpenAIError` if the request fails
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