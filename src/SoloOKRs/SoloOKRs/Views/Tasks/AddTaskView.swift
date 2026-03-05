// AddTaskView.swift
// SoloOKRs
//
// Updated on 2026-02-13: Simplified — no task types, no subtasks.

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let keyResult: KeyResult
    
    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: Priority = .medium
    
    // AI State
    @State private var suggestions: [String] = []
    @State private var rawSuggestionText: String = ""
    @State private var showingSuggestions = false
    @State private var isGettingSuggestions = false
    @State private var suggestionTask: Task<Void, Never>?
    @State private var suggestionError: String?
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // LEFT: Basic Info Form
                Form {
                    Section(LocalizedStringKey("Title")) {
                        TextField("", text: $title)
                            .font(.title3)
                    }
                    
                    Section(LocalizedStringKey("Due Date")) {
                        Toggle(LocalizedStringKey("Set Due Date"), isOn: $hasDueDate)
                        if hasDueDate {
                            DatePicker(LocalizedStringKey("Due Date"), selection: $dueDate, displayedComponents: .date)
                        }
                    }
                    
                    Section(LocalizedStringKey("Priority")) {
                        Picker(LocalizedStringKey("Priority"), selection: $priority) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Label(priority.displayName, systemImage: priority.icon)
                                    .tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .formStyle(.grouped)
                .contentMargins(.top, 50)
                .frame(minWidth: 280, idealWidth: 320)
                
                // RIGHT: Markdown Notes Editor
                VStack(alignment: .leading, spacing: 0) {
                    Text(LocalizedStringKey("Notes"))
                        .font(.headline)
                        .padding()
                    
                    MarkdownEditorView(
                        text: $description,
                        placeholder: String(localized: "Add notes (Markdown supported)...")
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top, 50)
                .frame(minWidth: 300)
            }
            .navigationTitle(LocalizedStringKey("New Task"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) { dismiss() }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        getSuggestions()
                    } label: {
                        Label(LocalizedStringKey("Suggest"), systemImage: "sparkles")
                    }
                    .disabled(isGettingSuggestions)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Add")) { addTask() }
                        .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingSuggestions) {
                NavigationStack {
                    List {
                        if isGettingSuggestions && suggestions.isEmpty {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text(LocalizedStringKey("Generating suggestions..."))
                                    .foregroundStyle(.secondary)
                            }
                        } else if let error = suggestionError {
                            Text(error)
                                .foregroundStyle(.red)
                        } else if suggestions.isEmpty && !isGettingSuggestions {
                            Text(LocalizedStringKey("No suggestions available."))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    title = suggestion
                                    showingSuggestions = false
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle(LocalizedStringKey("AI Suggestions"))
                    .toolbar {
                        if isGettingSuggestions {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(role: .destructive) {
                                    suggestionTask?.cancel()
                                    isGettingSuggestions = false
                                } label: {
                                    Label(LocalizedStringKey("Stop"), systemImage: "stop.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(LocalizedStringKey("Close")) { showingSuggestions = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .onDisappear {
                    suggestionTask?.cancel()
                    isGettingSuggestions = false
                }
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, minHeight: 600, idealHeight: 700, maxHeight: .infinity)
    }
    
    private func getSuggestions() {
        suggestions = []
        rawSuggestionText = ""
        suggestionError = nil
        isGettingSuggestions = true
        showingSuggestions = true
        
        suggestionTask?.cancel()
        suggestionTask = Task {
            do {
                let stream = AIService.shared.suggestTasksStream(for: keyResult)
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    rawSuggestionText += chunk
                    suggestions = parseJSONList(from: rawSuggestionText)
                }
            } catch {
                if !Task.isCancelled {
                    suggestionError = "Failed to get suggestions: \(error.localizedDescription)"
                    print("Failed to get suggestions: \(error)")
                }
            }
            isGettingSuggestions = false
        }
    }
    
    private func parseJSONList(from text: String) -> [String] {
        let cleanText = text.replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let data = cleanText.data(using: .utf8),
           let suggestions = try? JSONDecoder().decode([String].self, from: data) {
            return suggestions
        }
        
        // Fallback: split by newlines if JSON parsing fails/is incomplete
        return cleanText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && ($0.starts(with: "-") || $0.first?.isNumber == true) }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-1234567890. \"[],")) }
            .filter { !$0.isEmpty }
    }
    
    private func addTask() {
        let task = OKRTask(
            title: title,
            taskDescription: description,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            order: keyResult.tasks.count
        )
        
        task.keyResult = keyResult
        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    AddTaskView(keyResult: KeyResult(title: "Test KR"))
        .modelContainer(for: [KeyResult.self], inMemory: true)
}
