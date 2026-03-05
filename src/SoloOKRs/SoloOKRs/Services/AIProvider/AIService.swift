// AIService.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.
// Refactored 2026-03-05: Uses PromptManager for all prompts.

import Foundation
import SwiftUI

@Observable
@MainActor
class AIService {
    static let shared = AIService()

    var selectedProviderType: AIProviderType = .gemini {
        didSet { UserDefaults.standard.set(selectedProviderType.rawValue, forKey: "selectedProviderType") }
    }
    var isProcessing = false
    var lastError: AIError?

    var geminiAPIKey: String = "" {
        didSet { updateKeychain(geminiAPIKey, account: "apikey", service: "com.solookrs.gemini") }
    }
    var openAIAPIKey: String = "" {
        didSet { updateKeychain(openAIAPIKey, account: "apikey", service: "com.solookrs.openai") }
    }
    var anthropicAPIKey: String = "" {
        didSet { updateKeychain(anthropicAPIKey, account: "apikey", service: "com.solookrs.anthropic") }
    }
    var lmStudioAPIKey: String = "" {
        didSet { updateKeychain(lmStudioAPIKey, account: "apikey", service: "com.solookrs.lmstudio") }
    }
    var customAPIKey: String = "" {
        didSet { updateKeychain(customAPIKey, account: "apikey", service: "com.solookrs.custom") }
    }

    var ollamaEndpoint: String = "" {
        didSet { UserDefaults.standard.set(ollamaEndpoint, forKey: "ollamaEndpoint") }
    }
    var lmStudioEndpoint: String = "" {
        didSet { UserDefaults.standard.set(lmStudioEndpoint, forKey: "lmStudioEndpoint") }
    }
    var customEndpoint: String = "" {
        didSet { UserDefaults.standard.set(customEndpoint, forKey: "customEndpoint") }
    }

    var geminiModel: String = "" {
        didSet { UserDefaults.standard.set(geminiModel, forKey: "geminiModel") }
    }
    var openAIModel: String = "" {
        didSet { UserDefaults.standard.set(openAIModel, forKey: "openAIModel") }
    }
    var anthropicModel: String = "" {
        didSet { UserDefaults.standard.set(anthropicModel, forKey: "anthropicModel") }
    }
    var ollamaModel: String = "" {
        didSet { UserDefaults.standard.set(ollamaModel, forKey: "ollamaModel") }
    }
    var lmStudioModel: String = "" {
        didSet { UserDefaults.standard.set(lmStudioModel, forKey: "lmStudioModel") }
    }
    var customModel: String = "" {
        didSet { UserDefaults.standard.set(customModel, forKey: "customModel") }
    }
    
    private init() {
        if let stored = UserDefaults.standard.string(forKey: "selectedProviderType"),
           let type = AIProviderType(rawValue: stored) {
            self.selectedProviderType = type
        }
        
        self.geminiAPIKey = KeychainHelper.shared.readString(service: "com.solookrs.gemini", account: "apikey") ?? ""
        self.openAIAPIKey = KeychainHelper.shared.readString(service: "com.solookrs.openai", account: "apikey") ?? ""
        self.anthropicAPIKey = KeychainHelper.shared.readString(service: "com.solookrs.anthropic", account: "apikey") ?? ""
        self.lmStudioAPIKey = KeychainHelper.shared.readString(service: "com.solookrs.lmstudio", account: "apikey") ?? ""
        self.customAPIKey = KeychainHelper.shared.readString(service: "com.solookrs.custom", account: "apikey") ?? ""
        
        let rawOllama = UserDefaults.standard.string(forKey: "ollamaEndpoint") ?? "http://127.0.0.1:11434"
        self.ollamaEndpoint = rawOllama.hasSuffix("/") ? String(rawOllama.dropLast()) : rawOllama
        self.lmStudioEndpoint = UserDefaults.standard.string(forKey: "lmStudioEndpoint") ?? "http://localhost:1234"
        self.customEndpoint = UserDefaults.standard.string(forKey: "customEndpoint") ?? ""
        
        self.geminiModel = UserDefaults.standard.string(forKey: "geminiModel") ?? "gemini-1.5-flash"
        self.openAIModel = UserDefaults.standard.string(forKey: "openAIModel") ?? "gpt-4o"
        self.anthropicModel = UserDefaults.standard.string(forKey: "anthropicModel") ?? "claude-3-5-sonnet-20240620"
        self.ollamaModel = UserDefaults.standard.string(forKey: "ollamaModel") ?? "llama3"
        self.lmStudioModel = UserDefaults.standard.string(forKey: "lmStudioModel") ?? "local-model"
        self.customModel = UserDefaults.standard.string(forKey: "customModel") ?? ""
    }

    private func updateKeychain(_ value: String, account: String, service: String) {
        if value.isEmpty {
            KeychainHelper.shared.delete(service: service, account: account)
        } else {
            KeychainHelper.shared.save(value, service: service, account: account)
        }
    }

    var isConfigured: Bool {
        switch selectedProviderType {
        case .gemini: return !geminiAPIKey.isEmpty
        case .openai: return !openAIAPIKey.isEmpty
        case .anthropic: return !anthropicAPIKey.isEmpty
        case .ollama, .lmstudio: return true
        case .custom: return !customEndpoint.isEmpty
        }
    }

    var selectedModel: String {
        get {
            switch selectedProviderType {
            case .gemini: return geminiModel
            case .openai: return openAIModel
            case .anthropic: return anthropicModel
            case .ollama: return ollamaModel
            case .lmstudio: return lmStudioModel
            case .custom: return customModel
            }
        }
        set {
            switch selectedProviderType {
            case .gemini: geminiModel = newValue
            case .openai: openAIModel = newValue
            case .anthropic: anthropicModel = newValue
            case .ollama: ollamaModel = newValue
            case .lmstudio: lmStudioModel = newValue
            case .custom: customModel = newValue
            }
        }
    }

    // MARK: - Fetch Models

    var availableModels: [String] = []

    func fetchModels() async throws {
        guard isConfigured else {
            throw AIError.notConfigured
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        switch selectedProviderType {
        case .gemini:
             let urlString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(geminiAPIKey)"
             guard let url = URL(string: urlString) else { throw AIError.apiError("Invalid URL") }
             let (data, _) = try await URLSession.shared.data(from: url)
             let response = try JSONDecoder().decode(GeminiModelListResponse.self, from: data)
             let fetchedModels = response.models
                 .filter { $0.supportedGenerationMethods.contains("generateContent") }
                 .map { $0.name.replacingOccurrences(of: "models/", with: "") }
                 .sorted()
             
             self.availableModels = fetchedModels.isEmpty ? ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-1.0-pro"] : fetchedModels
             
        case .openai:
             let urlString = "https://api.openai.com/v1/models"
             guard let url = URL(string: urlString) else { throw AIError.apiError("Invalid URL") }
             var request = URLRequest(url: url)
             request.addValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
             let (data, _) = try await URLSession.shared.data(for: request)
             let response = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data)
             self.availableModels = response.data.map { $0.id }.sorted()

        case .anthropic:
             self.availableModels = ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307", "claude-2.1"]
             
        case .ollama:
             let urlString = "\(ollamaEndpoint)/api/tags"
             print("Fetching Ollama models from: \(urlString)")
             
             guard let url = URL(string: urlString) else { throw AIError.apiError("Invalid URL: \(urlString)") }
             
             do {
                 let (data, response) = try await URLSession.shared.data(from: url)
                 
                 if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                      throw AIError.apiError("Ollama returned HTTP \(httpResponse.statusCode)")
                 }
                 
                 if let jsonStr = String(data: data, encoding: .utf8) {
                     print("Ollama Response: \(jsonStr)")
                 }
                 
                 let decodedResponse = try JSONDecoder().decode(OllamaModelListResponse.self, from: data)
                 self.availableModels = decodedResponse.models.map { $0.name }.sorted()
             } catch {
                 print("Ollama Fetch Error: \(error)")
                 throw error
             }
             
        case .lmstudio:
             let urlString = "\(lmStudioEndpoint)/v1/models"
             guard let url = URL(string: urlString) else { throw AIError.apiError("Invalid URL") }
             var request = URLRequest(url: url)
             if !lmStudioAPIKey.isEmpty {
                 request.addValue("Bearer \(lmStudioAPIKey)", forHTTPHeaderField: "Authorization")
             }
             let (data, _) = try await URLSession.shared.data(for: request)
             let response = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data)
             self.availableModels = response.data.map { $0.id }.sorted()
             
        case .custom:
             let urlString = "\(customEndpoint)/v1/models"
             guard let url = URL(string: urlString) else { throw AIError.apiError("Invalid URL") }
             var request = URLRequest(url: url)
             if !customAPIKey.isEmpty {
                 request.addValue("Bearer \(customAPIKey)", forHTTPHeaderField: "Authorization")
             }
             let (data, _) = try await URLSession.shared.data(for: request)
             let response = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data)
             self.availableModels = response.data.map { $0.id }.sorted()
        }
        
        // Auto-select first model if current selection is invalid or empty
        if !availableModels.isEmpty {
            let current = selectedModel
            if current.isEmpty || !availableModels.contains(current) {
                selectedModel = availableModels[0]
            }
        }
    }

    // MARK: - Unified API Calls (using PromptManager)

    func analyzeOKR(_ objective: Objective) async throws -> String {
        let prompt = PromptManager.shared.resolvedAnalyzePrompt(for: objective)
        return try await generate(prompt: prompt)
    }

    func suggestKeyResults(for objective: Objective) async throws -> [String] {
        let prompt = PromptManager.shared.resolvedSuggestKRPrompt(for: objective)
        let text = try await generate(prompt: prompt)
        return parseJSONList(from: text)
    }

    func suggestTasks(for keyResult: KeyResult) async throws -> [String] {
        let prompt = PromptManager.shared.resolvedSuggestTaskPrompt(for: keyResult)
        let text = try await generate(prompt: prompt)
        return parseJSONList(from: text)
    }

    func evaluateKeyResult(krTitle: String, objectiveTitle: String) async throws -> String {
        let prompt = PromptManager.shared.resolvedEvaluateKRPrompt(objectiveTitle: objectiveTitle, krTitle: krTitle)
        return try await generate(prompt: prompt)
    }
    
    // MARK: - Unified Generate (routes to correct provider)
    
    private func generate(prompt: String) async throws -> String {
        guard isConfigured else {
            throw AIError.notConfigured
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        switch selectedProviderType {
        case .gemini:
            return try await generateWithGemini(prompt: prompt)
        case .ollama:
            return try await generateWithOllama(prompt: prompt)
        case .anthropic:
            return try await generateWithAnthropic(prompt: prompt)
        case .openai, .lmstudio, .custom:
            return try await generateWithOpenAICompatible(prompt: prompt)
        }
    }

    // MARK: - JSON Parsing
    
    private func parseJSONList(from text: String) -> [String] {
        let cleanText = text.replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let data = cleanText.data(using: .utf8),
           let suggestions = try? JSONDecoder().decode([String].self, from: data) {
            return suggestions
        }
        
        // Fallback: split by newlines if JSON parsing fails
        return cleanText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && ($0.starts(with: "-") || $0.first?.isNumber == true) }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-1234567890. ")) }
    }

    // MARK: - Gemini REST API Implementation
    
    private func generateWithGemini(prompt: String) async throws -> String {
        let model = geminiModel.isEmpty ? "gemini-1.5-flash" : geminiModel
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(geminiAPIKey)"
        guard let url = URL(string: urlString) else {
            throw AIError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GeminiRequest(contents: [
            GeminiContent(parts: [
                GeminiPart(text: prompt)
            ])
        ])
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError(NSError(domain: "Network", code: -1))
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw AIError.apiError(errorResponse.error.message)
            }
            throw AIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw AIError.apiError("No content generated")
        }
        
        return text
    }

    // MARK: - Ollama API Implementation
    
    private func generateWithOllama(prompt: String) async throws -> String {
        let model = ollamaModel.isEmpty ? "llama3" : ollamaModel
        let urlString = "\(ollamaEndpoint)/api/generate"
        
        guard let url = URL(string: urlString) else {
            throw AIError.apiError("Invalid URL: \(urlString)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OllamaGenerateRequest(
            model: model,
            prompt: prompt,
            stream: false
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("Ollama Error: \(errorStr)")
            }
            throw AIError.apiError("Ollama HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        return ollamaResponse.response
    }

    // MARK: - OpenAI Compatible API Implementation
    
    private func generateWithOpenAICompatible(prompt: String) async throws -> String {
        let (endpoint, apiKey, model) = getOpenAICompatibleConfig()
        
        guard let url = URL(string: "\(endpoint)/v1/chat/completions") else {
            throw AIError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = OpenAIChatRequest(
            model: model,
            messages: [OpenAIChatMessage(role: "user", content: prompt)]
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("OpenAI Error: \(errorStr)")
            }
            throw AIError.apiError("OpenAI Compatible HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let text = chatResponse.choices.first?.message.content else {
            throw AIError.invalidResponse
        }
        return text
    }
    
    private func getOpenAICompatibleConfig() -> (String, String, String) {
        switch selectedProviderType {
        case .openai:
            return ("https://api.openai.com", openAIAPIKey, openAIModel.isEmpty ? "gpt-4o" : openAIModel)
        case .lmstudio:
            return (lmStudioEndpoint, lmStudioAPIKey, lmStudioModel)
        case .custom:
            return (customEndpoint, customAPIKey, selectedModel)
        default:
            return ("", "", "")
        }
    }
    
    // MARK: - Anthropic API Implementation
    
    private func generateWithAnthropic(prompt: String) async throws -> String {
        let model = anthropicModel.isEmpty ? "claude-3-5-sonnet-20240620" : anthropicModel
        let urlString = "https://api.anthropic.com/v1/messages"
        
        guard let url = URL(string: urlString) else {
            throw AIError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody = AnthropicMessageRequest(
            model: model,
            max_tokens: 1024,
            messages: [AnthropicMessage(role: "user", content: prompt)]
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("Anthropic Error: \(errorStr)")
            }
            throw AIError.apiError("Anthropic HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        let anthropicResponse = try JSONDecoder().decode(AnthropicMessageResponse.self, from: data)
        guard let text = anthropicResponse.content.first?.text else {
            throw AIError.invalidResponse
        }
        return text
    }
}

// MARK: - Gemini REST Data Models

private struct GeminiRequest: Codable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
}

private struct GeminiErrorResponse: Codable {
    let error: GeminiErrorDetail
}

private struct GeminiErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String
}

// MARK: - API Response Models

struct GeminiModelListResponse: Codable {
    let models: [GeminiModel]
}

struct GeminiModel: Codable {
    let name: String
    let supportedGenerationMethods: [String]
}

struct OpenAIModelListResponse: Codable {
    let data: [OpenAIModel]
}

struct OpenAIModel: Codable {
    let id: String
}

struct OllamaModelListResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
}

struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
}

struct OllamaGenerateResponse: Codable {
    let model: String
    let response: String
    let done: Bool
}

// MARK: - OpenAI Compatible Chat Models

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
}

struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIChatResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIChatMessage
}

// MARK: - Anthropic Models

struct AnthropicMessageRequest: Codable {
    let model: String
    let max_tokens: Int
    let messages: [AnthropicMessage]
}

struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

struct AnthropicMessageResponse: Codable {
    let content: [AnthropicContent]
}

struct AnthropicContent: Codable {
    let text: String
}
