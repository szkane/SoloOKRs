// PromptSettingsView.swift
// SoloOKRs
//
// Settings tab for managing AI prompt templates.

import SwiftUI
import MarkdownUI

struct PromptSettingsView: View {
    @State private var selectedPrompt: PromptTemplateID? = .analyzeOKR
    @State private var editingText: String = ""
    @State private var showPreview = false
    @State private var showResetConfirmation = false
    
    private let promptManager = PromptManager.shared
    
    var body: some View {
        adaptiveSplit {
            // Left: prompt list
            List(PromptTemplateID.allCases, selection: $selectedPrompt) { template in
                HStack(spacing: 10) {
                    Image(systemName: template.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(LocalizedStringKey(template.displayName))
                                .font(.headline)
                            
                            if promptManager.hasCustomPrompt(for: template) {
                                Text("Custom")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.orange.opacity(0.2))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(LocalizedStringKey(template.description))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
                .tag(template)
            }
            .frame(minWidth: 200, idealWidth: 240)
            .listStyle(.sidebar)
        } right: {
            
            // Right: editor
            if let selected = selectedPrompt {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(selected.displayName))
                                .font(.title3.bold())
                            Text(LocalizedStringKey(selected.description))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Preview toggle
                        Toggle(isOn: $showPreview) {
                            Image(systemName: showPreview ? "eye.fill" : "eye")
                        }
                        .toggleStyle(.button)
                        .help("Toggle Preview")
                        
                        Button {
                            showResetConfirmation = true
                        } label: {
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        }
                        .disabled(!promptManager.hasCustomPrompt(for: selected))
                        .help("Reset to Default")
                    }
                    .padding()
                    
                    Divider()
                    
                    // Placeholders hint
                    HStack(spacing: 16) {
                        Label("Available placeholders:", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(placeholders(for: selected), id: \.self) { ph in
                            Text(ph)
                                .font(.caption.monospaced())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.bar)
                    
                    // Editor/Preview area
                    if showPreview {
                        adaptiveSplit {
                            promptEditor
                        } right: {
                            promptPreview
                        }
                    } else {
                        promptEditor
                    }
                }
                .onChange(of: selectedPrompt) { _, newValue in
                    if let newValue {
                        editingText = promptManager.prompt(for: newValue)
                    }
                }
                .onAppear {
                    editingText = promptManager.prompt(for: selected)
                }
                .onChange(of: editingText) { _, newValue in
                    if let selected = selectedPrompt {
                        // Only save custom if different from default
                        if newValue == promptManager.defaultPrompt(for: selected) {
                            promptManager.resetToDefault(for: selected)
                        } else {
                            promptManager.setCustomPrompt(newValue, for: selected)
                        }
                    }
                }
                .alert("Reset to Default?", isPresented: $showResetConfirmation) {
                    Button("Reset", role: .destructive) {
                        if let selected = selectedPrompt {
                            promptManager.resetToDefault(for: selected)
                            editingText = promptManager.prompt(for: selected)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will discard your custom prompt and restore the default template.")
                }
            } else {
                ContentUnavailableView("Select a Prompt", systemImage: "text.bubble", description: Text("Choose a prompt template from the list to customize it."))
            }
        }
        .navigationTitle("Prompts")
    }

    @ViewBuilder
    private func adaptiveSplit<Left: View, Right: View>(@ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) -> some View {
        #if os(macOS)
        HSplitView {
            left()
            right()
        }
        #else
        HStack(spacing: 0) {
            left()
            Divider()
            right()
        }
        #endif
    }
    
    // MARK: - Subviews
    
    private var promptEditor: some View {
        TextEditor(text: $editingText)
            .font(.body.monospaced())
            .scrollContentBackground(.hidden)
            .padding(12)
            .frame(minHeight: 200)
    }
    
    private var promptPreview: some View {
        ScrollView {
            if editingText.isEmpty {
                Text("Empty prompt")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Markdown(editingText)
                        .textSelection(.enabled)
                        .markdownTheme(.gitHub)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(16)
            }
        }
        .frame(minHeight: 200)
        .background(.background.secondary)
    }
    
    // MARK: - Helpers
    
    private func placeholders(for id: PromptTemplateID) -> [String] {
        switch id {
        case .analyzeOKR:
            return ["{{objective.title}}", "{{objective.description}}", "{{kr_list}}", "{{task_list}}", "{{currentLanguage}}"]
        case .suggestKR:
            return ["{{objective.title}}", "{{objective.description}}", "{{currentLanguage}}"]
        case .evaluateKR:
            return ["{{objective.title}}", "{{kr.title}}", "{{currentLanguage}}"]
        }
    }
}

#Preview {
    PromptSettingsView()
        .frame(width: 800, height: 500)
}
