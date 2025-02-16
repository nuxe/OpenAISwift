# OpenAISwift

A lightweight, modern Swift package for OpenAI's API with async/await and Combine support. Built for iOS 15+ and macOS 12+.

## Features

- Modern Swift async/await API
- Combine support for reactive workflows
- Type-safe request/response models
- Error handling

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/nuxe/OpenAISwift.git", from: "1.0.0")
]
```

Or in Xcode:
1. File > Add Packages...
2. Enter package URL: `https://github.com/nuxe/OpenAISwift.git`
3. Click "Add Package"

## Quick Start

```swift
import OpenAISwift

// Initialize the client
let client = OpenAIClient(apiKey: "your-api-key")

// Simple message sending
do {
    let response = try await client.sendMessage(
        "What is the capital of France?",
        model: "gpt-4"
    )
    print(response)
} catch {
    print("Error: \(error)")
}

// Advanced usage with custom parameters
let request = ChatRequest(
    model: "gpt-4",
    messages: [
        Message(role: "system", content: "You are a helpful assistant."),
        Message(role: "user", content: "Tell me about Swift.")
    ],
    temperature: 0.7,
    maxTokens: 150
)

do {
    let response = try await client.createChatCompletion(request)
    print(response.choices.first?.message.content ?? "")
} catch {
    print("Error: \(error)")
}

// Combine support
let cancellable = client.createChatCompletionPublisher(request)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { response in
            print(response.choices.first?.message.content ?? "")
        }
    )
```

## Error Handling

The library provides detailed error handling through the `OpenAIError` enum:

```swift
do {
    let response = try await client.sendMessage("Hello")
} catch OpenAIError.apiError(let code, let message) {
    print("API Error \(code): \(message)")
} catch OpenAIError.invalidURL {
    print("Invalid URL")
} catch OpenAIError.decodingError {
    print("Failed to decode response")
} catch {
    print("Unknown error: \(error)")
}
```

## Advanced Configuration

```swift
// Custom timeout
let client = OpenAIClient(
    apiKey: "your-api-key",
    timeout: 120 // 2 minutes
)

// System prompt
let response = try await client.sendMessage(
    "What is Swift?",
    model: "gpt-4",
    systemPrompt: "You are a Swift programming expert. Keep answers technical and concise."
)
```

## Requirements
- iOS 18.0+ / macOS 15.0+
- Swift 5.5+
- Xcode 16.0+

## License
This project is licensed under the MIT License.
