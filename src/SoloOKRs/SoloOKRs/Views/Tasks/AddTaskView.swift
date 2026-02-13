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
    @State private var showingSuggestions = false
    @State private var isGettingSuggestions = false
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // LEFT: Basic Info Form
                Form {
                    Section("Title") {
                        TextField("", text: $title)
                            .font(.title3)
                    }
                    
                    Section("Due Date") {
                        Toggle("Set Due Date", isOn: $hasDueDate)
                        if hasDueDate {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        }
                    }
                    
                    Section("Priority") {
                        Picker("Priority", selection: $priority) {
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
                    Text("Notes")
                        .font(.headline)
                        .padding()
                    
                    MarkdownEditorView(
                        text: $description,
                        placeholder: "Add notes (Markdown supported)..."
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top, 50)
                .frame(minWidth: 300)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                            await getSuggestions()
                        }
                    } label: {
                        Label("Suggest", systemImage: "sparkles")
                    }
                    .disabled(isGettingSuggestions)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addTask() }
                        .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingSuggestions) {
                NavigationStack {
                    List {
                        if suggestions.isEmpty {
                            Text("No suggestions available.")
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
                    .navigationTitle("AI Suggestions")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showingSuggestions = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, minHeight: 600, idealHeight: 700, maxHeight: .infinity)
    }
    
    private func getSuggestions() async {
        isGettingSuggestions = true
        do {
            suggestions = try await AIService.shared.suggestTasks(for: keyResult)
            showingSuggestions = true
        } catch {
            print("Failed to get suggestions: \(error)")
        }
        isGettingSuggestions = false
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
