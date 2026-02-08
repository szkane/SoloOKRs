// AIProviderSettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import SwiftUI

struct AIProviderSettingsView: View {
    @Bindable var aiService = AIService.shared
    @State private var geminiKey: String = ""
    @State private var showingKeyVisible = false
    
    var body: some View {
        Form {
            Section {
                Picker("Provider", selection: $aiService.selectedProviderType) {
                    ForEach(AIProviderType.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
            } header: {
                Text("Select Provider")
            } footer: {
                Text("Select which AI provider to use for analysis and suggestions.")
            }
            
            Section("Configuration") {
                switch aiService.selectedProviderType {
                case .gemini:
                    providerConfigSection(
                        title: "Gemini API Key",
                        keyBinding: Binding(get: { aiService.geminiAPIKey }, set: { aiService.geminiAPIKey = $0 }),
                        link: "https://aistudio.google.com/app/apikey"
                    )
                    
                case .openai:
                    providerConfigSection(
                        title: "OpenAI API Key",
                        keyBinding: Binding(get: { aiService.openAIAPIKey }, set: { aiService.openAIAPIKey = $0 }),
                        link: "https://platform.openai.com/api-keys"
                    )
                    
                case .anthropic:
                    providerConfigSection(
                        title: "Anthropic API Key",
                        keyBinding: Binding(get: { aiService.anthropicAPIKey }, set: { aiService.anthropicAPIKey = $0 }),
                        link: "https://console.anthropic.com/"
                    )
                    
                case .ollama:
                    VStack(alignment: .leading) {
                        TextField("Ollama Endpoint", text: $aiService.ollamaEndpoint)
                            .textFieldStyle(.roundedBorder)
                        modelSelectionView
                    }
                    
                case .lmstudio:
                    VStack(alignment: .leading) {
                        TextField("LM Studio Endpoint", text: $aiService.lmStudioEndpoint)
                            .textFieldStyle(.roundedBorder)
                        modelSelectionView
                    }
                    
                case .custom:
                    TextField("Custom Endpoint", text: $aiService.customEndpoint)
                }
            }
            
            if aiService.isConfigured {
                Section {
                    Label("AI Service Ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Section {
                    Label("Configuration Required", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("AI Providers")
        .onAppear {
            // Load existing key
            geminiKey = aiService.geminiAPIKey
            // specific to gemini or generally if configured
            if aiService.isConfigured && aiService.availableModels.isEmpty {
                 Task { try? await aiService.fetchModels() }
            }
        }
        .onChange(of: geminiKey) { _, newValue in
            aiService.geminiAPIKey = newValue
        }
        .onChange(of: aiService.selectedProviderType) { _, _ in
            aiService.availableModels = []
        }
    }
    
    // MARK: - Subviews
    
    private func providerConfigSection(title: String, keyBinding: Binding<String>, link: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
            HStack {
                if showingKeyVisible {
                    TextField("Enter API Key", text: keyBinding)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Enter API Key", text: keyBinding)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button {
                    showingKeyVisible.toggle()
                } label: {
                    Image(systemName: showingKeyVisible ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }
            
            Link("Get API Key", destination: URL(string: link)!)
                .font(.caption)
            
            Divider()
            
            modelSelectionView
        }
    }
    
    private var modelSelectionView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Model")
                Spacer()
                if aiService.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task {
                            do {
                                try await aiService.fetchModels()
                            } catch {
                                aiService.lastError = error as? AIError ?? .networkError(error)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(!aiService.isConfigured)
                    .help("Refresh Models")
                }
            }
            
            if !aiService.availableModels.isEmpty {
                Picker("Model", selection: $aiService.selectedModel) {
                     ForEach(aiService.availableModels, id: \.self) { model in
                         Text(model).tag(model)
                     }
                }
                .pickerStyle(.menu)
            } else {
                if let error = aiService.lastError {
                    Text("Error: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text(aiService.isConfigured ? "Tap refresh to load models" : "Configure provider first")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    AIProviderSettingsView()
}
