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
    @State private var analysisTask: Task<Void, Never>?
    @State private var showingAnalysisSheet = false
    @State private var selectedObjectiveForAnalysis: Objective?
    @State private var showingReviewSheet: Objective?
    @State private var showingReviewHistory: Objective?
    @AppStorage("preferredLanguage") private var preferredLanguage = ""
    
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
            ObjectiveTabSegmentedControl(selection: $selectedTab)
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
                            analyzeObjective(objective)
                        }
                    )
                    .tag(objective)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            analyzeObjective(objective)
                        } label: {
                            Label("Analyze with AI", systemImage: "sparkles")
                        }
                        .tint(.indigo)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeActionsContent(for: objective)
                    }
                    .contextMenu {
                        contextMenuContent(for: objective)
                    }
                }
            }
            .animation(.spring(duration: 0.3), value: filteredObjectives.count)
        }
        .navigationTitle("Objectives")

        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .help("Add Objective")
                }
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
                    if isAnalyzing {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(role: .destructive) {
                                analysisTask?.cancel()
                                isAnalyzing = false
                            } label: {
                                Label("Stop", systemImage: "stop.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingAnalysisSheet = false }
                    }
                }
            }
            .frame(minWidth: 500, minHeight: 500)
            .onDisappear {
                analysisTask?.cancel()
                isAnalyzing = false
            }
        }
        .onChange(of: selectedObjective) { _, _ in
            selectedKeyResult = nil
        }
        .sheet(item: $showingReviewSheet) { obj in
            CreateReviewView(objective: obj)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
        }
        .sheet(item: $showingReviewHistory) { obj in
            ReviewHistoryView(objective: obj)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
        }
    }

    @ViewBuilder
    private func contextMenuContent(for objective: Objective) -> some View {
        Button {
            analyzeObjective(objective)
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
            .disabled(objective.status == .active && canMarkAsAchieved(objective))
        }
        
        if objective.status == .active {
            Divider()
            
            let canAchieve = canMarkAsAchieved(objective)
            
            Button {
                markAsAchieved(objective)
            } label: {
                Label("Mark as Achieved", systemImage: "trophy")
            }
            .disabled(!canAchieve)
        }
    }
    
    // MARK: - Achieved Logic
    private func canMarkAsAchieved(_ objective: Objective) -> Bool {
        // Needs review history
        if objective.reviews.isEmpty { return false }
        
        // All tasks must be completed
        for kr in objective.keyResults {
            for task in kr.tasks {
                if !task.isCompleted {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func markAsAchieved(_ objective: Objective) {
        withAnimation {
            objective.status = .achieved
            objective.updatedAt = Date()
            selectedTab = .achieved
        }
    }
    
    private func analyzeObjective(_ objective: Objective) {
        selectedObjectiveForAnalysis = objective
        analysisResult = ""
        isAnalyzing = true
        showingAnalysisSheet = true
        
        analysisTask?.cancel()
        analysisTask = Task {
            do {
                let stream = AIService.shared.analyzeOKRStream(objective)
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    if analysisResult == nil {
                        analysisResult = chunk
                    } else {
                        analysisResult? += chunk
                    }
                }
            } catch {
                if !Task.isCancelled {
                    analysisResult = (analysisResult ?? "") + "\n\n### Analysis Failed\n\n**Error details:** \(error.localizedDescription)\n\nPlease check your AI Settings and ensure the selected provider/model is available."
                }
            }
            isAnalyzing = false
        }
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
    
    private func unarchiveObjective(_ objective: Objective) {
        withAnimation {
            objective.status = .draft
            objective.archivedAt = nil
            objective.updatedAt = Date()
        }
    }
    
    @ViewBuilder
    private func swipeActionsContent(for objective: Objective) -> some View {
        switch objective.status {
        case .draft:
            Button(role: .destructive) {
                archiveObjective(objective)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            
            Button {
                promoteToActive(objective)
            } label: {
                Label("Active", systemImage: "arrow.up.circle")
            }
            .tint(.green)
            
        case .active, .review:
            let canAchieve = canMarkAsAchieved(objective)
            
            Button {
                showingReviewSheet = objective
            } label: {
                Label("Review", systemImage: "calendar.badge.plus")
            }
            .tint(.teal)

            if !objective.reviews.isEmpty {
                Button {
                    showingReviewHistory = objective
                } label: {
                    Label("History", systemImage: "clock")
                }
                .tint(.blue)
            }
            
            if !canAchieve {
                Button(role: .destructive) {
                    archiveObjective(objective)
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            }
            
            if canAchieve {
                Button {
                    markAsAchieved(objective)
                } label: {
                    Label("Achieved", systemImage: "trophy")
                }
                .tint(.orange)
            }
            
        case .archived:
            Button {
                unarchiveObjective(objective)
            } label: {
                Label("Unarchive", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
            
        case .achieved:
            EmptyView()
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
        HStack(alignment: .top, spacing: 12) {
            CircularProgressView(
                progress: objective.progress,
                color: color(for: objective.status)
            )
            .frame(width: 44, height: 44)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(objective.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    if ReviewModeManager.shared.isInReviewMode && (objective.status == .active || objective.status == .review) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
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
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            VStack {
                Spacer()
                Divider()
            }
        )
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
    
    private func color(for status: OKRStatus) -> Color {
        switch status {
        case .draft: return Color(red: 0.00, green: 0.48, blue: 1.00)
        case .active: return Color(red: 0.20, green: 0.80, blue: 0.20)
        case .achieved: return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .archived: return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .review: return Color(red: 0.20, green: 0.80, blue: 0.20) // Same as active
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.3),
                    lineWidth: 4
                )
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            Text(String(format: "%.0f%%", progress * 100))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
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
