// KeyResultListView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import SwiftUI
import SwiftData

struct KeyResultListView: View {
    let objective: Objective
    @Binding var selectedKeyResult: KeyResult?
    @AppStorage("preferredLanguage") private var preferredLanguage = ""
    
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    
    // AI Analysis State
    @State private var analysisResult: String?
    @State private var isAnalyzing = false
    @State private var showingAnalysisSheet = false
    
    var sortedKeyResults: [KeyResult] {
        objective.keyResults.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        List(selection: $selectedKeyResult) {
            ForEach(sortedKeyResults) { keyResult in
                KeyResultRowView(keyResult: keyResult, objective: objective, selectedKeyResult: $selectedKeyResult)
                    .tag(keyResult)
            }
        }
        .navigationTitle(objective.title)
        // Toolbar buttons removed as per request
        // .toolbar { ... }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button(LocalizedStringKey("Add Key Result"), systemImage: "plus") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .disabled(!objective.isEditable)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddKeyResultView(objective: objective)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
        }
        .sheet(isPresented: $showingEditSheet) {
            EditObjectiveView(objective: objective)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
        }
        .sheet(isPresented: $showingAnalysisSheet) {
            NavigationStack {
                // ... (Keep existing Analysis Sheet Content)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Spacer()
                            Button {
                                promoteToActive()
                                showingAnalysisSheet = false
                            } label: {
                                Label(LocalizedStringKey("Promote to Active"), systemImage: "arrow.up.circle.fill")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            Spacer()
                        }
                        .padding(.bottom)
                        
                        Text(analysisResult ?? String(localized: "No analysis available."))
                            .textSelection(.enabled)
                    }
                    .padding()
                }
                .navigationTitle(LocalizedStringKey("AI Analysis"))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedStringKey("Done")) { showingAnalysisSheet = false }
                    }
                }
            }
            .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
            .frame(minWidth: 400, minHeight: 400)
        }
        // Add context menu to List background or empty area for Objective Actions?
        // User asked for double-click/right-click on "Objectives" (which are in the list in parent view)
        // For KeyResultListView, keeping it concise.
    }
    
    private func analyzeObjective() async {
        isAnalyzing = true
        do {
            let result = try await AIService.shared.analyzeOKR(objective)
            analysisResult = result
            showingAnalysisSheet = true
        } catch {
            print("Analysis failed: \(error)")
        }
        isAnalyzing = false
    }
    
    private func promoteToActive() {
        withAnimation {
            objective.status = .active
            objective.updatedAt = Date()
        }
    }
}

struct KeyResultRowView: View {
    let keyResult: KeyResult
    let objective: Objective 
    @Binding var selectedKeyResult: KeyResult?
    @AppStorage("preferredLanguage") private var preferredLanguage = ""
    
    @State private var showingEditSheet = false
    
    private var canEdit: Bool {
        keyResult.isEditable
    }
    
    private var completedTasks: Int {
        keyResult.tasks.filter { $0.isCompleted }.count
    }
    
    private var totalTasks: Int {
        keyResult.tasks.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.blue)
                Text(keyResult.title)
                    .font(.headline)
                Spacer()
                Text("\(Int(keyResult.progress * 100))%")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: keyResult.progress)
                .tint(progressColor)
            
            HStack {
                if keyResult.selfScore != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                        Text("Score: \(keyResult.selfScore!)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                    Text("\(completedTasks)/\(totalTasks) Tasks")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if canEdit {
                showingEditSheet = true
            }
        }
        .onTapGesture(count: 1) {
            selectedKeyResult = keyResult
        }
        .contextMenu {
            if canEdit {
                Button {
                    showingEditSheet = true
                } label: {
                    Label(LocalizedStringKey("Edit Key Result"), systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    objective.keyResults.removeAll { $0.id == keyResult.id }
                } label: {
                    Label(LocalizedStringKey("Delete"), systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditKeyResultView(keyResult: keyResult)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
        }
    }
    
    private var progressColor: Color {
        if keyResult.progress >= 1.0 { return .green }
        if keyResult.progress >= 0.7 { return .blue }
        if keyResult.progress >= 0.3 { return .orange }
        return .red
    }
}

#Preview {
    let objective = Objective(title: "Preview Objective")
    return KeyResultListView(objective: objective, selectedKeyResult: .constant(nil))
        .modelContainer(for: [Objective.self], inMemory: true)
}
