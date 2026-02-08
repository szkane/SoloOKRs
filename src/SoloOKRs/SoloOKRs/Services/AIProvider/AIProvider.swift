// AIProvider.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import Foundation

enum AIProviderType: String, CaseIterable, Codable {
    case gemini = "Gemini"
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case ollama = "Ollama"
    case lmstudio = "LM Studio"
    case custom = "Custom"
}

protocol AIProvider {
    var name: String { get }
    var type: AIProviderType { get }
    var isConfigured: Bool { get }

    func complete(prompt: String, systemPrompt: String?) async throws -> String
}

enum AIError: LocalizedError {
    case notConfigured
    case networkError(Error)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI provider is not configured. Please add your API key in Settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI provider."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
