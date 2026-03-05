// AddKeyResultView.swift
// SoloOKRs
//
// Simplified after KR type migration (2026-02-06).
// Updated 2026-03-05: Auto-focus, removed detail label, KR evaluation with Suggest.

import SwiftUI
import SwiftData
import MarkdownUI

struct AddKeyResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let objective: Objective
    
    @State private var title = ""
    @FocusState private var isTitleFocused: Bool
    
    // AI State
    @State private var evaluationResult: String?
    @State private var showingEvaluation = false
    @State private var isEvaluating = false
    @State private var evaluationTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            Form {
                TextField(LocalizedStringKey("Key Result"), text: $title)
                    .textFieldStyle(.plain)
                    .focused($isTitleFocused)
                    .font(.body)
            }
            .formStyle(.grouped)
            .navigationTitle(LocalizedStringKey("New Key Result"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) { dismiss() }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        evaluateKR()
                    } label: {
                        if isEvaluating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label(LocalizedStringKey("Suggest"), systemImage: "sparkles")
                        }
                    }
                    .disabled(title.isEmpty || isEvaluating)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Add")) { addKeyResult() }
                        .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingEvaluation) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let result = evaluationResult {
                                Markdown(result)
                                    .textSelection(.enabled)
                                    .markdownTheme(.gitHub)
                            } else {
                                ContentUnavailableView(LocalizedStringKey("No Evaluation"), systemImage: "sparkles", description: Text(LocalizedStringKey("Evaluation results will appear here.")))
                            }
                        }
                        .padding()
                    }
                    .navigationTitle(LocalizedStringKey("KR Evaluation"))
                    .toolbar {
                        if isEvaluating {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(role: .destructive) {
                                    evaluationTask?.cancel()
                                    isEvaluating = false
                                } label: {
                                    Label(LocalizedStringKey("Stop"), systemImage: "stop.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(LocalizedStringKey("Close")) { showingEvaluation = false }
                        }
                    }
                }
                .frame(minWidth: 450, minHeight: 400)
                .onDisappear {
                    evaluationTask?.cancel()
                    isEvaluating = false
                }
            }
        }
        .frame(minWidth: 400, minHeight: 180)
        .onAppear {
            isTitleFocused = true
        }
    }
    
    private func evaluateKR() {
        evaluationResult = ""
        isEvaluating = true
        showingEvaluation = true
        
        evaluationTask?.cancel()
        evaluationTask = Task {
            do {
                let stream = AIService.shared.evaluateKeyResultStream(
                    krTitle: title,
                    objectiveTitle: objective.title
                )
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    if evaluationResult == nil {
                        evaluationResult = chunk
                    } else {
                        evaluationResult? += chunk
                    }
                }
            } catch {
                if !Task.isCancelled {
                    evaluationResult = (evaluationResult ?? "") + "\n\n### Evaluation Failed\n\n**Error:** \(error.localizedDescription)\n\nPlease check your AI Settings."
                }
            }
            isEvaluating = false
        }
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
