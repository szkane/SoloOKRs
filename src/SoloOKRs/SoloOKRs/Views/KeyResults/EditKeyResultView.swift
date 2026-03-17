// EditKeyResultView.swift
// SoloOKRs
//
// Simplified after KR type migration (2026-02-06).

import SwiftUI
import SwiftData
import MarkdownUI

struct EditKeyResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var keyResult: KeyResult
    
    // AI State
    @State private var evaluationResult: String?
    @State private var showingEvaluation = false
    @State private var isEvaluating = false
    @State private var evaluationTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            Form {
                if !keyResult.isEditable {
                    Section {
                        Label("Read Only", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(LocalizedStringKey("Details")) {
                    HStack(spacing: 12) {
                        TextField(LocalizedStringKey("Title"), text: $keyResult.title)
                            .textFieldStyle(.plain)
                            .font(.body)
                        
                        Spacer()
                        
                        Button {
                            evaluateKR(text: keyResult.title)
                        } label: {
                            if isEvaluating {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "sparkles")
                                    .help(LocalizedStringKey("Check with AI"))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                        .disabled(keyResult.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isEvaluating)
                    }
                }
                .disabled(!keyResult.isEditable)
                

                
                Section(LocalizedStringKey("Progress")) {
                    let completedCount = keyResult.tasks.filter { $0.isCompleted }.count
                    let totalCount = keyResult.tasks.count
                    
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("\(completedCount) / \(totalCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            
                            Text(LocalizedStringKey("tasks completed"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    
                    ProgressView(value: keyResult.progress)
                        .tint(keyResult.progress >= 1.0 ? .green : .blue)
                        .scaleEffect(y: 2)
                        .clipShape(.rect(cornerRadius: 4))
                }
                // Progress is derived, so no manual editing here anyway except maybe adding tasks (which is separate)
            }
            .formStyle(.grouped)
            .navigationTitle(LocalizedStringKey("Edit Key Result"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Done")) {
                        keyResult.updatedAt = Date()
                        dismiss()
                    }
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
        .frame(minWidth: 500, minHeight: 400)
        .onDisappear {
            evaluationTask?.cancel()
        }
    }
    
    private func evaluateKR(text: String) {
        evaluationResult = ""
        isEvaluating = true
        showingEvaluation = true
        
        evaluationTask?.cancel()
        evaluationTask = Task {
            do {
                let objectiveTitle = keyResult.objective?.title ?? ""
                let stream = AIService.shared.evaluateKeyResultStream(
                    krTitle: text,
                    objectiveTitle: objectiveTitle
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
            if !Task.isCancelled {
                isEvaluating = false
            }
        }
    }
}
