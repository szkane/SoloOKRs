// AddKeyResultView.swift
// SoloOKRs
//
// Simplified after KR type migration (2026-02-06).
// Updated 2026-03-05: Auto-focus, removed detail label, KR evaluation with Suggest.
// Updated 2026-03-17: Multiple KR inputs, per-item evaluation, auto-suggest for empty objectives.

import SwiftUI
import SwiftData

struct KRInput: Identifiable {
    let id = UUID()
    var text: String
    var isSelected: Bool = true
}

struct AddKeyResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let objective: Objective
    
    @State private var inputs: [KRInput] = [KRInput(text: "")]
    @FocusState private var focusedField: UUID?
    
    // AI State
    @State private var isSuggesting = false
    @State private var suggestTask: Task<Void, Never>?
    
    @State private var evaluatingId: UUID? = nil
    @State private var evaluationResult: String?
    @State private var showingEvaluation = false
    @State private var evaluationTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header / Suggest State
                    if isSuggesting {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(LocalizedStringKey("Generating Key Results..."))
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                    }
                    
                    // KR Inputs List
                    VStack(spacing: 16) {
                        ForEach($inputs) { $input in
                            HStack(alignment: .center, spacing: 16) {
                                Toggle("", isOn: $input.isSelected)
                                    .labelsHidden()
                                    #if os(macOS)
                                    .toggleStyle(.checkbox)
                                    #endif
                                    .controlSize(.regular)
                                
                                TextField(LocalizedStringKey("Enter Key Result..."), text: $input.text)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .focused($focusedField, equals: input.id)
                                    .disabled(!input.isSelected)
                                
                                Spacer()
                                
                                // Evaluate Button
                                Button {
                                    evaluateKR(id: input.id, text: input.text)
                                } label: {
                                    if evaluatingId == input.id {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .help(LocalizedStringKey("Check with AI"))
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.blue)
                                .disabled(input.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || evaluatingId != nil)
                                
                                // Delete row button
                                if inputs.count > 1 {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            inputs.removeAll { $0.id == input.id }
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red.opacity(0.8))
                                            .imageScale(.medium)
                                    }
                                    .buttonStyle(.plain)
                                    .help(LocalizedStringKey("Delete"))
                                } else {
                                    // Placeholder to keep spacing stable when delete is hidden
                                    Image(systemName: "minus.circle.fill")
                                        .opacity(0)
                                        .imageScale(.medium)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 1)
                            )
                        }
                    }
                    
                    HStack {
                        // Add another button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                let newInput = KRInput(text: "", isSelected: true)
                                inputs.append(newInput)
                                // Dispatch async to ensure UI updates before focusing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    focusedField = newInput.id
                                }
                            }
                        } label: {
                            Label(LocalizedStringKey("Add another"), systemImage: "plus.circle")
                                .font(.callout.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                        
                        Spacer()
                    }
                    .padding(.leading, 4)
                    
                    // Generate AI Hero Button
                    if inputs.count == 1 && inputs[0].text.isEmpty {
                        VStack {
                            Divider()
                                .padding(.vertical, 16)
                            
                            Button {
                                suggestKeyResults()
                            } label: {
                                Label(LocalizedStringKey("Generate key results by AI"), systemImage: "sparkles")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .controlSize(.large)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(24)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(LocalizedStringKey("New Key Results"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Add Selected")) { addKeyResults() }
                        .disabled(!hasValidSelection)
                }
            }
            .sheet(isPresented: $showingEvaluation) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let result = evaluationResult {
                                AIResponseView(text: result, isStreaming: evaluatingId != nil)
                            } else {
                                ContentUnavailableView(LocalizedStringKey("No Evaluation"), systemImage: "sparkles", description: Text(LocalizedStringKey("Evaluation results will appear here.")))
                            }
                        }
                        .padding()
                    }
                    .navigationTitle(LocalizedStringKey("KR Evaluation"))
                    .toolbar {
                        if evaluatingId != nil {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(role: .destructive) {
                                    evaluationTask?.cancel()
                                    evaluatingId = nil
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
                    evaluatingId = nil
                }
            }
        }
        .frame(minWidth: 500, minHeight: 350)
        .onDisappear {
            suggestTask?.cancel()
            evaluationTask?.cancel()
        }
    }
    
    private var hasValidSelection: Bool {
        inputs.contains { $0.isSelected && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func suggestKeyResults() {
        isSuggesting = true
        suggestTask?.cancel()
        
        suggestTask = Task {
            do {
                let suggestions = try await AIService.shared.suggestKeyResults(for: objective)
                if !Task.isCancelled {
                    if !suggestions.isEmpty {
                        withAnimation {
                            inputs = suggestions.map { KRInput(text: $0, isSelected: true) }
                        }
                    }
                }
            } catch {
                print("Suggestion failed: \(error)")
            }
            isSuggesting = false
        }
    }
    
    private func evaluateKR(id: UUID, text: String) {
        evaluationResult = ""
        evaluatingId = id
        showingEvaluation = true
        
        evaluationTask?.cancel()
        evaluationTask = Task {
            do {
                let stream = AIService.shared.evaluateKeyResultStream(
                    krTitle: text,
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
            if !Task.isCancelled {
                evaluatingId = nil
            }
        }
    }
    
    private func addKeyResults() {
        var addedCount = 0
        let currentOrderIndex = objective.keyResults.count
        
        for input in inputs where input.isSelected {
            let cleanText = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanText.isEmpty {
                let kr = KeyResult(
                    title: cleanText,
                    order: currentOrderIndex + addedCount
                )
                kr.objective = objective
                modelContext.insert(kr)
                addedCount += 1
            }
        }
        
        if addedCount > 0 {
            dismiss()
        }
    }
}

#Preview {
    AddKeyResultView(objective: Objective(title: "Preview Objective"))
        .modelContainer(for: [Objective.self], inMemory: true)
}
