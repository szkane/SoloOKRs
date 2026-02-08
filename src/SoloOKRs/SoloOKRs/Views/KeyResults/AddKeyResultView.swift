// AddKeyResultView.swift
// SoloOKRs
//
// Simplified after KR type migration (2026-02-06).

import SwiftUI
import SwiftData

struct AddKeyResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let objective: Objective
    
    @State private var title = ""
    
    // AI State
    @State private var suggestions: [String] = []
    @State private var showingSuggestions = false
    @State private var isGettingSuggestions = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Key Result Title", text: $title)
                        .textFieldStyle(.plain)
                }
                
                Section {
                    Text("Progress will be calculated from task completion.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    Text("Add tasks after creating this Key Result.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Key Result")
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
                    Button("Add") { addKeyResult() }
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
        .frame(minWidth: 400, minHeight: 250)
    }
    
    private func getSuggestions() async {
        isGettingSuggestions = true
        do {
            suggestions = try await AIService.shared.suggestKeyResults(for: objective)
            showingSuggestions = true
        } catch {
            print("Failed to get suggestions: \(error)")
        }
        isGettingSuggestions = false
    }
    
    private func addKeyResult() {
        let kr = KeyResult(
            title: title,
            order: objective.keyResults.count
        )
        kr.objective = objective
        modelContext.insert(kr)
        dismiss()
    }
}

#Preview {
    AddKeyResultView(objective: Objective(title: "Test"))
        .modelContainer(for: [Objective.self], inMemory: true)
}
