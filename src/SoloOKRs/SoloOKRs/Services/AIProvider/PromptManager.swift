// PromptManager.swift
// SoloOKRs
//
// Manages customizable AI prompt templates. Stores user overrides in UserDefaults.

import Foundation

// MARK: - Prompt Template Identifiers

enum PromptTemplateID: String, CaseIterable, Identifiable {
    case analyzeOKR = "analyzeOKR"
    case suggestKR = "suggestKR"
    case suggestTask = "suggestTask"
    case evaluateKR = "evaluateKR"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .analyzeOKR: return "Analyze OKR"
        case .suggestKR: return "Suggest Key Results"
        case .suggestTask: return "Suggest Tasks"
        case .evaluateKR: return "Evaluate Key Result"
        }
    }
    
    var description: String {
        switch self {
        case .analyzeOKR: return "Analyzes an Objective and its KRs for OKR best practices"
        case .suggestKR: return "Suggests measurable Key Results for an Objective"
        case .suggestTask: return "Suggests concrete tasks for a Key Result"
        case .evaluateKR: return "Evaluates a single KR for quality and suggests improvements"
        }
    }
    
    var icon: String {
        switch self {
        case .analyzeOKR: return "magnifyingglass.circle"
        case .suggestKR: return "list.bullet.circle"
        case .suggestTask: return "checkmark.circle"
        case .evaluateKR: return "star.circle"
        }
    }
}

// MARK: - Prompt Manager

@Observable
@MainActor
class PromptManager {
    static let shared = PromptManager()
    
    private init() {}
    
    // MARK: - Get / Set Custom Prompts
    
    /// Returns the user's custom prompt for this template+language, or the default if none is set.
    func prompt(for id: PromptTemplateID) -> String {
        let lang = currentLanguageCode()
        let key = "prompt_\(id.rawValue)_\(lang)"
        if let custom = UserDefaults.standard.string(forKey: key), !custom.isEmpty {
            return custom
        }
        return defaultPrompt(for: id)
    }
    
    /// Returns true if the user has a custom override for this prompt in the current language.
    func hasCustomPrompt(for id: PromptTemplateID) -> Bool {
        let lang = currentLanguageCode()
        let key = "prompt_\(id.rawValue)_\(lang)"
        if let custom = UserDefaults.standard.string(forKey: key), !custom.isEmpty {
            return true
        }
        return false
    }
    
    /// Saves a custom prompt for this template in the current language.
    func setCustomPrompt(_ text: String, for id: PromptTemplateID) {
        let lang = currentLanguageCode()
        let key = "prompt_\(id.rawValue)_\(lang)"
        UserDefaults.standard.set(text, forKey: key)
    }
    
    /// Resets to default by removing the custom override.
    func resetToDefault(for id: PromptTemplateID) {
        let lang = currentLanguageCode()
        let key = "prompt_\(id.rawValue)_\(lang)"
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - Resolve Prompts with Data
    
    func resolvedAnalyzePrompt(for objective: Objective) -> String {
        var template = prompt(for: .analyzeOKR)
        template = template.replacingOccurrences(of: "{{objective.title}}", with: objective.title)
        template = template.replacingOccurrences(of: "{{objective.description}}", with: objective.objectiveDescription)
        
        let krList = objective.keyResults.enumerated().map { i, kr in
            "\(i + 1). \(kr.title)"
        }.joined(separator: "\n")
        template = template.replacingOccurrences(of: "{{kr_list}}", with: krList.isEmpty ? "(none)" : krList)
        
        let taskList = objective.keyResults.flatMap { kr in
            kr.tasks.map { "- [\(kr.title)] \($0.title)" }
        }.joined(separator: "\n")
        template = template.replacingOccurrences(of: "{{task_list}}", with: taskList.isEmpty ? "(none)" : taskList)
        
        template = template.replacingOccurrences(of: "{{currentLanguage}}", with: currentLanguageDisplayName())
        return template
    }
    
    func resolvedSuggestKRPrompt(for objective: Objective) -> String {
        var template = prompt(for: .suggestKR)
        template = template.replacingOccurrences(of: "{{objective.title}}", with: objective.title)
        template = template.replacingOccurrences(of: "{{objective.description}}", with: objective.objectiveDescription)
        template = template.replacingOccurrences(of: "{{currentLanguage}}", with: currentLanguageDisplayName())
        return template
    }
    
    func resolvedSuggestTaskPrompt(for keyResult: KeyResult) -> String {
        var template = prompt(for: .suggestTask)
        template = template.replacingOccurrences(of: "{{keyResult.title}}", with: keyResult.title)
        template = template.replacingOccurrences(of: "{{currentLanguage}}", with: currentLanguageDisplayName())
        return template
    }
    
    func resolvedEvaluateKRPrompt(objectiveTitle: String, krTitle: String) -> String {
        var template = prompt(for: .evaluateKR)
        template = template.replacingOccurrences(of: "{{objective.title}}", with: objectiveTitle)
        template = template.replacingOccurrences(of: "{{kr.title}}", with: krTitle)
        template = template.replacingOccurrences(of: "{{currentLanguage}}", with: currentLanguageDisplayName())
        return template
    }
    
    // MARK: - Language Helpers
    
    func currentLanguageCode() -> String {
        let preferred = UserDefaults.standard.string(forKey: "preferredLanguage") ?? ""
        if preferred.isEmpty {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        // Normalize: "zh-Hans" → "zh-Hans", "en" → "en"
        return preferred
    }
    
    func currentLanguageDisplayName() -> String {
        let code = currentLanguageCode()
        let languageMap: [String: String] = [
            "en": "English",
            "zh-Hans": "Simplified Chinese (简体中文)",
            "zh-Hant": "Traditional Chinese (繁體中文)",
            "ja": "Japanese (日本語)",
            "ko": "Korean (한국어)",
            "de": "German (Deutsch)",
            "fr": "French (Français)",
            "es": "Spanish (Español)",
            "pt-BR": "Portuguese (Português)"
        ]
        return languageMap[code] ?? "English"
    }
    
    // MARK: - Default Templates
    
    func defaultPrompt(for id: PromptTemplateID) -> String {
        switch id {
        case .analyzeOKR:
            return """
            You are an OKR methodology expert. Analyze the following Objective and its Key Results for adherence to OKR best practices.
            
            ## Input
            - Objective Title: {{objective.title}}
            - Objective Description: {{objective.description}}
            - Key Results:
            {{kr_list}}
            - Tasks:
            {{task_list}}
            
            ## Analysis Criteria
            1. Is the Objective inspirational, qualitative, and time-bound?
            2. For each KR, evaluate:
               - Alignment with the Objective
               - Measurability (has clear metrics)
               - Verifiability (can be objectively verified)
               - Outcome-oriented (not output/task-based)
               - Ambitious but realistic
            3. Do the KRs collectively cover the Objective sufficiently?
            
            ## Output
            Provide structured Markdown feedback with:
            - Overall assessment
            - Per-KR analysis (✅ strengths / ⚠️ improvements)
            - Suggested optimized KR rewrites (if applicable)
            
            **Output language: {{currentLanguage}}**
            """
            
        case .suggestKR:
            return """
            You are an OKR expert. Suggest 3-5 measurable Key Results for the following Objective.
            Each KR must be: Aligned, Verifiable, Measurable, Outcome-oriented, Ambitious but realistic.
            
            Objective: "{{objective.title}}"
            Context: "{{objective.description}}"
            
            Return ONLY a JSON array of strings. No markdown, no explanation.
            **Output language: {{currentLanguage}}**
            """
            
        case .suggestTask:
            return """
            Suggest 3-5 concrete tasks/actions to help achieve this Key Result.
            Return ONLY a JSON array of strings. No markdown, no explanation.
            
            Key Result: "{{keyResult.title}}"
            **Output language: {{currentLanguage}}**
            """
            
        case .evaluateKR:
            return """
            You are an OKR methodology expert. Evaluate the following Key Result against OKR standards.
            
            Objective: "{{objective.title}}"
            Key Result: "{{kr.title}}"
            
            Evaluate on:
            1. Aligned with Objective — Is it strongly related?
            2. Verifiable — Can completion be objectively verified?
            3. Measurable — Does it have a clear metric?
            4. Outcome-oriented — Is it a result, not a task/output?
            5. Ambitious but realistic — Is it stretching yet achievable?
            
            Provide:
            - A brief verdict for each criterion (✅ / ⚠️ / ❌)
            - One optimized rewrite of the KR that meets all criteria
            
            Format as Markdown. Mark the optimized KR with `> **Suggested:** ...` so the user can identify and copy it.
            **Output language: {{currentLanguage}}**
            """
        }
    }
}
