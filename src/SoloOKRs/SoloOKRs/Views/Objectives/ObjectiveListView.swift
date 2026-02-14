// ObjectiveListView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import SwiftUI
import SwiftData

struct ObjectiveListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Objective.order) private var objectives: [Objective]
    
    @Binding var selectedObjective: Objective?
    @Binding var selectedKeyResult: KeyResult?
    
    @State private var showingAddSheet = false
    @State private var selectedTab: ObjectiveTab = .active
    
    // AI Analysis State
    @State private var analysisResult: String?
    @State private var isAnalyzing = false
    @State private var showingAnalysisSheet = false
    
    enum ObjectiveTab: String, CaseIterable {
        case draft = "Draft"
        case active = "Active"
        case achieved = "Achieved"
        case archived = "Archived"
    }
    
    var filteredObjectives: [Objective] {
        switch selectedTab {
        case .draft:
            return objectives.filter { $0.status == .draft }
        case .active:
            // Review mode objectives also show in Active tab as per user request
            return objectives.filter { $0.status == .active || $0.status == .review }
        case .achieved:
            return objectives.filter { $0.status == .achieved }
        case .archived:
            return objectives.filter { $0.status == .archived }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(ObjectiveTab.allCases, id: \.self) { tab in
                    Text(LocalizedStringKey(tab.rawValue))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if isAnalyzing {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analyzing Data...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)
            }
            
            List(selection: $selectedObjective) {
                ForEach(filteredObjectives) { objective in
                    ObjectiveRowView(objective: objective, selectedObjective: $selectedObjective, onPublish: {
                        Task { await analyzeObjective(objective) }
                    })
                        .tag(objective)
                        .contextMenu {
                            contextMenuContent(for: objective)
                        }
                }
            }
            .animation(.spring(duration: 0.3), value: filteredObjectives.count)
        }
        .navigationTitle("Objectives")

        // Task 2: Review Mode Button Location - moved to bottom safe area
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button {
                        if ReviewModeManager.shared.isInReviewMode {
                            ReviewModeManager.shared.exitReviewMode()
                        } else {
                            ReviewModeManager.shared.enterReviewMode()
                        }
                    } label: {
                        Label(ReviewModeManager.shared.isInReviewMode ? "Exit Review" : "Review Mode", systemImage: ReviewModeManager.shared.isInReviewMode ? "pencil.circle.fill" : "pencil.circle")
                            .font(.headline)
                    }
                    .tint(ReviewModeManager.shared.isInReviewMode ? .orange : .accentColor)
                    
                    Spacer()
                    
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Objective", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                }
                .padding()
                .background(.regularMaterial)
            }
        }

        .sheet(isPresented: $showingAddSheet) {
            AddObjectiveView()
        }
        .sheet(isPresented: $showingAnalysisSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let analysisObjective = selectedObjectiveForAnalysis, analysisObjective.status == .draft {
                            HStack {
                                Spacer()
                                Button {
                                    promoteToActive(analysisObjective)
                                    showingAnalysisSheet = false
                                } label: {
                                    Label("Promote to Active", systemImage: "arrow.up.circle.fill")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                Spacer()
                            }
                            .padding(.bottom)
                        }
                        
                        if let result = analysisResult {
                            Text(LocalizedStringKey(result))
                                .textSelection(.enabled)
                        } else {
                            ContentUnavailableView("No Analysis", systemImage: "text.magnifyingglass", description: Text("Run analysis to see feedback."))
                        }
                    }
                    .padding()
                }
                .navigationTitle("AI Analysis")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingAnalysisSheet = false }
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 400)
        }
        .onChange(of: selectedObjective) { _, _ in
            selectedKeyResult = nil
        }
        .onChange(of: ReviewModeManager.shared.isInReviewMode) { _, isInReviewMode in
            if isInReviewMode {
                selectedTab = .active
            }
        }
    }
    
    @State private var selectedObjectiveForAnalysis: Objective?

    @ViewBuilder
    private func contextMenuContent(for objective: Objective) -> some View {
        Button {
            Task {
                await analyzeObjective(objective)
            }
        } label: {
            Label("Analyze with AI", systemImage: "sparkles")
        }
        
        if objective.status == .draft {
            Button {
                promoteToActive(objective)
            } label: {
                Label("Publish to Active", systemImage: "arrow.up.circle")
            }
        }
        
        Divider()
        
        if objective.status == .archived {
            Button("Unarchive") {
                objective.status = .draft
                objective.archivedAt = nil
                objective.updatedAt = Date()
            }
        } else {
            Button("Archive", role: .destructive) {
                archiveObjective(objective)
            }
        }
    }
    
    private func analyzeObjective(_ objective: Objective) async {
        selectedObjectiveForAnalysis = objective
        isAnalyzing = true
        do {
            let result = try await AIService.shared.analyzeOKR(objective)
            analysisResult = result
            showingAnalysisSheet = true
        } catch {
            analysisResult = "### Analysis Failed\n\n**Error details:** \(error.localizedDescription)\n\nPlease checks your AI Settings and ensure the selected provider/model is available."
            showingAnalysisSheet = true
        }
        isAnalyzing = false
    }
    
    private func promoteToActive(_ objective: Objective) {
        withAnimation {
            objective.status = .active
            objective.updatedAt = Date()
            selectedTab = .active
        }
    }
    
    private func archiveObjective(_ objective: Objective) {
        withAnimation {
            objective.status = .archived
            objective.archivedAt = Date()
            objective.updatedAt = Date()
            if selectedObjective == objective {
                selectedObjective = nil
            }
        }
    }
}

struct ObjectiveRowView: View {
    let objective: Objective
    @Binding var selectedObjective: Objective?
    var onPublish: (() -> Void)? = nil
    
    @State private var isOverduePulsing = false
    @State private var showingEditSheet = false
    
    private var canEdit: Bool {
        ReviewModeManager.shared.canEditOKR(status: objective.status)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
             // ... (Keep content identical, just wrapper changes)
            HStack {
                Text(objective.title)
                    .font(.headline)
                
                Spacer()
                
                if objective.status == .draft, let onPublish = onPublish {
                    Button {
                        onPublish()
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Analyze and Publish")
                }
                
                if ReviewModeManager.shared.isInReviewMode && (objective.status == .active || objective.status == .review) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Text("\(Int(objective.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: objective.progress)
            }
            
            if !objective.objectiveDescription.isEmpty {
                Text(objective.objectiveDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            HStack {
                Text("\(objective.keyResults.count) Key Results")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if objective.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse, options: .repeating, value: isOverduePulsing)
                        .onAppear { isOverduePulsing = true }
                }
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
            selectedObjective = objective
        }
        .contextMenu {
            if canEdit {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit Objective", systemImage: "pencil")
                }
            }
            // Add other context actions here if needed (Archive/Delete handled in parent list context menu normally, 
            // but can duplicate here if Row captures all events)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditObjectiveView(objective: objective)
        }
    }
    

}

#Preview {
    ObjectiveListView(
        selectedObjective: .constant(nil),
        selectedKeyResult: .constant(nil)
    )
    .modelContainer(for: [Objective.self], inMemory: true)
}
