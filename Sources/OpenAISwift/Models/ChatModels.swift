import Foundation

/// A request to create a chat completion with OpenAI's API.
///
/// This struct represents a request to the chat completions endpoint, supporting
/// all available parameters for fine-tuning the response.
///
/// Example usage:
/// ```swift
/// let request = ChatRequest(
///     model: "gpt-4",
///     messages: [
///         Message(role: "system", content: "You are a helpful assistant"),
///         Message(role: "user", content: "Hello!")
///     ],
///     temperature: 0.7
/// )
/// ```
public struct ChatRequest: Codable, Sendable {
    /// The ID of the model to use (e.g., "gpt-4", "gpt-3.5-turbo")
    public let model: String
    
    /// The messages to generate chat completions for
    public let messages: [Message]
    
    /// What sampling temperature to use, between 0 and 2
    /// Higher values like 0.8 will make the output more random,
    /// while lower values like 0.2 will make it more focused and deterministic
    public let temperature: Double?
    
    /// An alternative to sampling with temperature
    /// The model considers the results of the tokens with top_p probability mass
    public let topP: Double?
    
    /// How many chat completion choices to generate for each input message
    public let n: Int?
    
    /// Whether to stream partial message deltas
    public let stream: Bool?
    
    /// Up to 4 sequences where the API will stop generating further tokens
    public let stop: [String]?
    
    /// The maximum number of tokens to generate in the chat completion
    public let maxTokens: Int?
    
    /// Number between -2.0 and 2.0. Positive values penalize new tokens based on
    /// whether they appear in the text so far, increasing the model's likelihood
    /// to talk about new topics
    public let presencePenalty: Double?
    
    /// Number between -2.0 and 2.0. Positive values penalize new tokens based on
    /// their existing frequency in the text so far, decreasing the model's likelihood
    /// to repeat the same line verbatim
    public let frequencyPenalty: Double?
    
    /// A unique identifier representing your end-user
    public let user: String?
    
    private enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case topP = "top_p"
        case n, stream, stop
        case maxTokens = "max_tokens"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case user
    }
    
    public init(
        model: String,
        messages: [Message],
        temperature: Double? = nil,
        topP: Double? = nil,
        n: Int? = nil,
        stream: Bool? = nil,
        stop: [String]? = nil,
        maxTokens: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        user: String? = nil
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.topP = topP
        self.n = n
        self.stream = stream
        self.stop = stop
        self.maxTokens = maxTokens
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.user = user
    }
}

/// A message in a chat conversation.
///
/// Messages are used to construct the conversation history for chat completions.
/// Each message has a role (system, user, or assistant) and content.
///
/// Example usage:
/// ```swift
/// let systemMessage = Message(role: "system", content: "You are a helpful assistant")
/// let userMessage = Message(role: "user", content: "Hello!")
/// ```
public struct Message: Codable, Sendable {
    /// The role of the message author. Must be one of: "system", "user", or "assistant"
    public let role: String
    
    /// The content of the message
    public let content: String
    
    /// An optional name for the participant
    public let name: String?
    
    public init(role: String, content: String, name: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
    }
}

/// The response from a chat completion request.
///
/// This struct contains the generated completions along with metadata about the response.
public struct ChatResponse: Codable, Sendable {
    /// Unique identifier for the response
    public let id: String
    
    /// The type of object returned, usually "chat.completion"
    public let object: String
    
    /// The Unix timestamp of when the response was generated
    public let created: Int
    
    /// The model used to generate the response
    public let model: String
    
    /// The list of generated completions
    public let choices: [Choice]
    
    /// Usage statistics for the request
    public let usage: Usage
    
    /// A single completion choice from the model
    public struct Choice: Codable, Sendable {
        /// The index of this choice in the list of choices
        public let index: Int
        
        /// The generated message
        public let message: Message
        
        /// The reason why the model stopped generating tokens
        public let finishReason: String?
        
        private enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    /// Token usage statistics for the request
    public struct Usage: Codable, Sendable {
        /// Number of tokens in the prompt
        public let promptTokens: Int
        
        /// Number of tokens in the generated completion
        public let completionTokens: Int
        
        /// Total number of tokens used in the request
        public let totalTokens: Int
        
        private enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
} 