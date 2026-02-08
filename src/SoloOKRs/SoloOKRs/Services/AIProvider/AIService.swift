// AIService.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import Foundation
import SwiftUI

@Observable
@MainActor
class AIService {
    static let shared = AIService()

    var selectedProviderType: AIProviderType {
        get {
            if let stored = UserDefaults.standard.string(forKey: "selectedProviderType"),
               let type = AIProviderType(rawValue: stored) {
                return type
            }
            return .gemini
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedProviderType")
        }
    }
    var isProcessing = false
    var lastError: AIError?

    private init() {}

    var isConfigured: Bool {
        // Check if current provider has API key
        switch selectedProviderType {
        case .gemini:
            return !geminiAPIKey.isEmpty
        case .openai:
            return !openAIAPIKey.isEmpty
        case .anthropic:
            return !anthropicAPIKey.isEmpty
        case .ollama, .lmstudio:
            return true  // Local providers don't need API key
        case .custom:
            return !customEndpoint.isEmpty
        }
    }

    // API Keys stored via Keychain
    var geminiAPIKey: String {
        get { KeychainHelper.shared.readString(service: "com.solookrs.gemini", account: "apikey") ?? "" }
        set {
            if newValue.isEmpty {
                KeychainHelper.shared.delete(service: "com.solookrs.gemini", account: "apikey")
            } else {
                KeychainHelper.shared.save(newValue, service: "com.solookrs.gemini", account: "apikey")
            }
        }
    }

    var openAIAPIKey: String {
        get { KeychainHelper.shared.readString(service: "com.solookrs.openai", account: "apikey") ?? "" }
        set {
            if newValue.isEmpty {
                KeychainHelper.shared.delete(service: "com.solookrs.openai", account: "apikey")
            } else {
                KeychainHelper.shared.save(newValue, service: "com.solookrs.openai", account: "apikey")
            }
        }
    }

    var anthropicAPIKey: String {
        get { KeychainHelper.shared.readString(service: "com.solookrs.anthropic", account: "apikey") ?? "" }
        set {
            if newValue.isEmpty {
                KeychainHelper.shared.delete(service: "com.solookrs.anthropic", account: "apikey")
            } else {
                KeychainHelper.shared.save(newValue, service: "com.solookrs.anthropic", account: "apikey")
            }
        }
    }

    var ollamaEndpoint: String {
        get { 
            let stored = UserDefaults.standard.string(forKey: "ollamaEndpoint") ?? "http://127.0.0.1:11434"
            // Ensure no trailing slash
            return stored.hasSuffix("/") ? String(stored.dropLast()) : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: "ollamaEndpoint") }
    }

    var lmStudioEndpoint: String {
        get { UserDefaults.standard.string(forKey: "lmStudioEndpoint") ?? "http://localhost:1234" }
        set { UserDefaults.standard.set(newValue, forKey: "lmStudioEndpoint") }
    }

    var customEndpoint: String {
        get { UserDefaults.standard.string(forKey: "customEndpoint") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "customEndpoint") }
    }

    var geminiModel: String {
        get { UserDefaults.standard.string(forKey: "geminiModel") ?? "gemini-1.5-flash" }
        set { UserDefaults.standard.set(newValue, forKey: "geminiModel") }
    }
    
    var openAIModel: String {
        get { UserDefaults.standard.string(forKey: "openAIModel") ?? "gpt-4o" }
        set { UserDefaults.standard.set(newValue, forKey: "openAIModel") }
    }
    
    var anthropicModel: String {
        get { UserDefaults.standard.string(forKey: "anthropicModel") ?? "claude-3-5-sonnet-20240620" }
        set { UserDefaults.standard.set(newValue, forKey: "anthropicModel") }
    }
    
    var ollamaModel: String {
        get { UserDefaults.standard.string(forKey: "ollamaModel") ?? "llama3" }
        set { UserDefaults.standard.set(newValue, forKey: "ollamaModel") }
    }
    
    var lmStudioModel: String {
        get { UserDefaults.standard.string(forKey: "lmStudioModel") ?? "local-model" }
        set { UserDefaults.standard.set(newValue, forKey: "lmStudioModel") }
    }
    
    var selectedModel: String {
        get {
            switch selectedProviderType {
            case .gemini: return geminiModel
            case .openai: return openAIModel
            case .anthropic: return anthropicModel
            case .ollama: return ollamaModel
            case .lmstudio: return lmStudioModel
            case .custom: return "custom"
            }
        }
        set {
            switch selectedProviderType {
            case .gemini: geminiModel = newValue
            case .openai: openAIModel = newValue
            case .anthropic: anthropicModel = newValue
            case .ollama: ollamaModel = newValue
            case .lmstudio: lmStudioModel = newValue
            case .custom: break
            }
        }
    }

    // MARK: - API Calls

    var availableModels: [String] = []

    func fetchModels() async throws {
        // isConfigured handles provider-specific checks (e.g. true for Ollama even without key)
        guard isConfigured else {
            throw AIError.notConfigured
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        switch selectedProviderType {
        case .gemini:
             // Gemini API list models
             let urlString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(geminiAPIKey)"
             guard let url = URL(string: urlString) else { throw AIError.apiError("Invalid URL") }
             let (data, _) = try await URLSession.shared.data(from: url)
             let response = try JSONDecoder().decode(GeminiModelListResponse.self, from: data)
             // Filter for generateContent supported models
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
             // Anthropic models are typically static or fetched via similar API if available. 
             // Currently best to provide a standard list if API is experimental.
             // But let's try a standard list as fallback or minimal implementation
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
                 throw error // Re-throw to be caught by UI
             }
             
        case .lmstudio:
             let urlString = "\(lmStudioEndpoint)/v1/models"
             guard let url = URL(string: urlString) else { throw AIError.apiError("Invalid URL") }
             let (data, _) = try await URLSession.shared.data(from: url)
             let response = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data) // LM Studio mimics OpenAI
             self.availableModels = response.data.map { $0.id }.sorted()
             
        case .custom:
             self.availableModels = ["custom-model"]
        }
        
        // Auto-select first model if current selection is invalid or empty
        if !availableModels.isEmpty {
            let current = selectedModel
            if current.isEmpty || !availableModels.contains(current) {
                selectedModel = availableModels[0]
            }
        }
    }

    // MARK: - API Calls

    func analyzeOKR(_ objective: Objective) async throws -> String {
        guard isConfigured else {
            throw AIError.notConfigured
        }

        isProcessing = true
        defer { isProcessing = false }

        switch selectedProviderType {
        case .gemini:
            return try await analyzeWithGemini(objective)
        case .ollama:
            return try await analyzeWithOllama(objective)
        default:
            try await Task.sleep(for: .seconds(1))
            return "Analysis for \(selectedProviderType.rawValue) is not fully implemented yet."
        }
    }
    
    private func analyzeWithOllama(_ objective: Objective) async throws -> String {
        let prompt = """
        Analyze the following OKR Objective for quality, clarity, and measurability.
        Provide constructive feedback on strengths and specific suggestions for improvement.
        
        Objective Title: "\(objective.title)"
        Description: "\(objective.objectiveDescription)"
        Status: \(objective.status.displayName)
        
        Format the response with Markdown using headers and bullet points.
        """
        return try await generateWithOllama(prompt: prompt)
    }

    func suggestKeyResults(for objective: Objective) async throws -> [String] {
        guard isConfigured else {
            throw AIError.notConfigured
        }

        isProcessing = true
        defer { isProcessing = false }

        switch selectedProviderType {
        case .gemini:
            return try await suggestKeyResultsWithGemini(objective)
        case .ollama:
            return try await suggestKeyResultsWithOllama(objective)
        default:
            try await Task.sleep(for: .seconds(1))
            return ["Suggestion 1", "Suggestion 2", "Suggestion 3"]
        }
    }

    private func suggestKeyResultsWithOllama(_ objective: Objective) async throws -> [String] {
        let prompt = """
        Suggest 3-5 Key Results (measurable outcomes) for the following Objective.
        Return ONLY a JSON array of strings, with no other text or markdown formatting.
        
        Objective: "\(objective.title)"
        Context: "\(objective.objectiveDescription)"
        """
        let text = try await generateWithOllama(prompt: prompt)
        return parseJSONList(from: text)
    }

    func suggestTasks(for keyResult: KeyResult) async throws -> [String] {
        guard isConfigured else {
            throw AIError.notConfigured
        }

        isProcessing = true
        defer { isProcessing = false }

        switch selectedProviderType {
        case .gemini:
            return try await suggestTasksWithGemini(keyResult)
        case .ollama:
            return try await suggestTasksWithOllama(keyResult)
        default:
             try await Task.sleep(for: .seconds(1))
             return ["Task 1", "Task 2"]
        }
    }

    private func suggestTasksWithOllama(_ keyResult: KeyResult) async throws -> [String] {
         let prompt = """
         Suggest 3-5 concrete tasks/actions to help achieve this Key Result.
         Return ONLY a JSON array of strings, with no other text or markdown formatting.
         
         Key Result: "\(keyResult.title)"
         """
        let text = try await generateWithOllama(prompt: prompt)
        return parseJSONList(from: text)
    }
    
    // MARK: - Gemini REST API Implementation
    
    private func generateContent(prompt: String) async throws -> String {
        // Use selected model, default to 1.5-flash if somehow empty
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
            // Try to parse error message
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
    
    private func analyzeWithGemini(_ objective: Objective) async throws -> String {
        let prompt = """
        Analyze the following OKR Objective for quality, clarity, and measurability.
        Provide constructive feedback on strengths and specific suggestions for improvement.
        
        Objective Title: "\(objective.title)"
        Description: "\(objective.objectiveDescription)"
        Status: \(objective.status.displayName)
        
        Format the response with Markdown using headers and bullet points.
        """
        
        return try await generateContent(prompt: prompt)
    }
    
    private func suggestKeyResultsWithGemini(_ objective: Objective) async throws -> [String] {
        let prompt = """
        Suggest 3-5 Key Results (measurable outcomes) for the following Objective.
        Return ONLY a JSON array of strings, with no other text or markdown formatting.
        
        Objective: "\(objective.title)"
        Context: "\(objective.objectiveDescription)"
        """
        
        let text = try await generateContent(prompt: prompt)
        return parseJSONList(from: text)
    }
    
    private func suggestTasksWithGemini(_ keyResult: KeyResult) async throws -> [String] {
         let prompt = """
         Suggest 3-5 concrete tasks/actions to help achieve this Key Result.
         Return ONLY a JSON array of strings, with no other text or markdown formatting.
         
         Key Result: "\(keyResult.title)"
         """
         
        let text = try await generateContent(prompt: prompt)
        return parseJSONList(from: text)
    }
    
    private func parseJSONList(from text: String) -> [String] {
        // Basic cleaning to handle potential markdown code blocks
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

    // MARK: - Ollama API Implementation
    
    private func generateWithOllama(prompt: String) async throws -> String {
        let model = ollamaModel.isEmpty ? "llama3" : ollamaModel // Fallback
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
