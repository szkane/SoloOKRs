// ObjectiveListView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.
// Updated 2026-03-05: Magnifying glass button for analyze, MarkdownUI analysis sheet.

import SwiftUI
import SwiftData
import MarkdownUI

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
    @State private var selectedObjectiveForAnalysis: Objective?
    @State private var showingReviewSheet: Objective?
    @State private var showingReviewHistory: Objective?
    
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
                    ObjectiveRowView(
                        objective: objective,
                        selectedObjective: $selectedObjective,
                        onAnalyze: {
                            Task { await analyzeObjective(objective) }
                        }
                    )
                    .tag(objective)
                    .contextMenu {
                        contextMenuContent(for: objective)
                    }
                }
            }
            .animation(.spring(duration: 0.3), value: filteredObjectives.count)
        }
        .navigationTitle("Objectives")

        // Bottom bar: Add Objective only
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
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
                            Markdown(result)
                                .textSelection(.enabled)
                                .markdownTheme(.gitHub)
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
            .frame(minWidth: 500, minHeight: 500)
        }
        .onChange(of: selectedObjective) { _, _ in
            selectedKeyResult = nil
        }
        .sheet(item: $showingReviewSheet) { obj in
            CreateReviewView(objective: obj)
        }
        .sheet(item: $showingReviewHistory) { obj in
            ReviewHistoryView(objective: obj)
        }
    }

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
        
        // Review actions (for active objectives)
        if objective.status == .active || objective.status == .review {
            Button {
                showingReviewSheet = objective
            } label: {
                Label("New Review", systemImage: "calendar.badge.plus")
            }
        }
        
        if !objective.reviews.isEmpty {
            Button {
                showingReviewHistory = objective
            } label: {
                Label("Review History (\(objective.reviews.count))", systemImage: "calendar.badge.clock")
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
            analysisResult = "### Analysis Failed\n\n**Error details:** \(error.localizedDescription)\n\nPlease check your AI Settings and ensure the selected provider/model is available."
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
    var onAnalyze: (() -> Void)? = nil
    
    @State private var isOverduePulsing = false
    @State private var showingEditSheet = false
    
    private var canEdit: Bool {
        ReviewModeManager.shared.canEditOKR(status: objective.status)
    }
    
    private var isSelected: Bool {
        selectedObjective?.id == objective.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(objective.title)
                    .font(.headline)
                
                Spacer()
                
                // Magnifying glass button for draft objectives (analyze)
                if objective.status == .draft, let onAnalyze = onAnalyze {
                    Button {
                        onAnalyze()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .blue)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(isSelected ? .white.opacity(0.2) : Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Analyze with AI")
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
