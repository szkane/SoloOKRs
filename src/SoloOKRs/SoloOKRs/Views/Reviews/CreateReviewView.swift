// CreateReviewView.swift
// SoloOKRs
//
// Form to create a new review for a specific Objective.
// Updated 2026-03-05: Chip pickers, task counts, status banner, i18n.

import SwiftUI
import SwiftData

struct CreateReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let objective: Objective
    
    @State private var reviewType: ReviewType = .weekly
    @State private var overallNotes: String = ""
    @State private var krEntries: [KREntryDraft] = []
    @State private var expandedKR: UUID? = nil
    @State private var isSaving = false
    
    struct KREntryDraft: Identifiable {
        let id: UUID
        let krTitle: String
        let keyResult: KeyResult
        var completedTasks: Int = 0
        var totalTasks: Int = 0
        var currentValue: Double = 0
        var targetValue: Double = 100
        var completionPercent: Double = 0
        var trend: ReviewTrend = .flat
        var status: KRReviewStatus = .onTrack
        var statusReason: String = ""
        var progress: String = ""
        var blockers: String = ""
        var nextSteps: String = ""
        var adjustmentNotes: String = ""
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    reviewTypeCard
                    krEntriesSection
                    overallNotesCard
                }
                .padding(20)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(Text("New Review — \(objective.title)"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveReview()
                    } label: {
                        Text("Save Review")
                            .fontWeight(.semibold)
                    }
                    .disabled(isSaving)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 600)
        .onAppear {
            populateKREntries()
            if let first = krEntries.first {
                expandedKR = first.id
            }
        }
    }
    
    // MARK: - Review Type Card
    
    private var reviewTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Review Type", systemImage: "calendar")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(ReviewType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { reviewType = type }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            Text(type.displayName)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(reviewType == type ? Color.accentColor : Color.clear)
                        .foregroundStyle(reviewType == type ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(reviewType == type ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
    
    // MARK: - KR Entries Section
    
    private var krEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Key Results", systemImage: "list.bullet.circle")
                    .font(.headline)
                Spacer()
                Text("\(krEntries.count) items")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            if krEntries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No Key Results to review")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach($krEntries) { $entry in
                    krEntryCard(entry: $entry)
                }
            }
        }
    }
    
    // MARK: - KR Entry Card
    
    private func krEntryCard(entry: Binding<KREntryDraft>) -> some View {
        let isExpanded = expandedKR == entry.wrappedValue.id
        
        return VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedKR = isExpanded ? nil : entry.wrappedValue.id
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: entry.wrappedValue.status.icon)
                        .foregroundStyle(entry.wrappedValue.status.color)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.wrappedValue.krTitle)
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        // Task count
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.square")
                                .font(.caption2)
                            Text("\(entry.wrappedValue.completedTasks)/\(entry.wrappedValue.totalTasks) Tasks")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if entry.wrappedValue.currentValue > 0 || entry.wrappedValue.targetValue != 100 {
                        Text("\(formatNumber(entry.wrappedValue.currentValue))/\(formatNumber(entry.wrappedValue.targetValue))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(Int(entry.wrappedValue.completionPercent))%")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(entry.wrappedValue.status.color)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                Divider().padding(.horizontal, 14)
                
                VStack(spacing: 16) {
                    metricsRow(entry: entry)
                    
                    Divider()
                    
                    // Status & Trend chips
                    statusAndTrendChips(entry: entry)
                    
                    // Status banner (prominent icon + label)
                    statusBanner(entry: entry)
                    
                    Divider()
                    
                    textFieldsGroup(entry: entry)
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isExpanded ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Metrics Row
    
    private func metricsRow(entry: Binding<KREntryDraft>) -> some View {
        HStack(spacing: 16) {
            metricField("Current", value: entry.currentValue)
                .onChange(of: entry.wrappedValue.currentValue) { _, _ in
                    updateCompletion(entry: entry)
                }
            
            metricField("Target", value: entry.targetValue)
                .onChange(of: entry.wrappedValue.targetValue) { _, _ in
                    updateCompletion(entry: entry)
                }
            
            // Completion
            VStack(spacing: 4) {
                Text("Done")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(Int(entry.wrappedValue.completionPercent))%")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(entry.wrappedValue.status.color)
                    .frame(height: 22)
            }
            .frame(width: 55)
            
            Divider().frame(height: 40)
            
            // Task progress
            VStack(spacing: 4) {
                Text("Tasks")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(entry.wrappedValue.completedTasks)/\(entry.wrappedValue.totalTasks)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(
                        entry.wrappedValue.totalTasks > 0 && entry.wrappedValue.completedTasks == entry.wrappedValue.totalTasks
                        ? .green : .primary
                    )
                    .frame(height: 22)
            }
            .frame(width: 55)
        }
    }
    
    private func metricField(_ label: String, value: Binding<Double>) -> some View {
        VStack(spacing: 4) {
            Text(LocalizedStringKey(label))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("0", value: value, format: .number)
                .textFieldStyle(.plain)
                .font(.title3.monospacedDigit())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 70)
        }
    }
    
    // MARK: - Status & Trend Chips
    
    private func statusAndTrendChips(entry: Binding<KREntryDraft>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(KRReviewStatus.allCases, id: \.self) { s in
                        let isSelected = entry.wrappedValue.status == s
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                entry.wrappedValue.status = s
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: s.icon)
                                    .font(.caption)
                                Text(s.displayName)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? s.color : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Trend chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Trend")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(ReviewTrend.allCases, id: \.self) { t in
                        let isSelected = entry.wrappedValue.trend == t
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                entry.wrappedValue.trend = t
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: t.icon)
                                    .font(.caption)
                                Text(t.displayName)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? t.swiftUIColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Status Banner (Fix #3: prominent status icon after selection)
    
    private func statusBanner(entry: Binding<KREntryDraft>) -> some View {
        let s = entry.wrappedValue.status
        
        return HStack(spacing: 10) {
            Image(systemName: s.icon)
                .font(.title2)
                .foregroundStyle(s.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(s.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(s.color)
                
                if !entry.wrappedValue.statusReason.isEmpty {
                    Text(entry.wrappedValue.statusReason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: entry.wrappedValue.trend.icon)
                .font(.title3)
                .foregroundStyle(entry.wrappedValue.trend.swiftUIColor)
        }
        .padding(12)
        .background(s.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Text Fields Group
    
    private func textFieldsGroup(entry: Binding<KREntryDraft>) -> some View {
        VStack(spacing: 12) {
            compactTextField(
                icon: "info.circle",
                label: "Status Reason",
                placeholder: "Why this status?",
                text: entry.statusReason,
                color: .secondary
            )
            
            compactTextField(
                icon: "arrow.up.right.circle",
                label: "Progress",
                placeholder: "Key achievements this period...",
                text: entry.progress,
                color: .green,
                multiline: true
            )
            
            compactTextField(
                icon: "hand.raised.circle",
                label: "Blockers",
                placeholder: "Impediments or risks...",
                text: entry.blockers,
                color: .red,
                multiline: true
            )
            
            compactTextField(
                icon: "arrow.right.circle",
                label: "Next Steps",
                placeholder: "Key actions planned...",
                text: entry.nextSteps,
                color: .blue,
                multiline: true
            )
            
            compactTextField(
                icon: "slider.horizontal.3",
                label: "Adjustments",
                placeholder: "Changes to target or strategy...",
                text: entry.adjustmentNotes,
                color: .orange
            )
        }
    }
    
    private func compactTextField(
        icon: String,
        label: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        color: Color,
        multiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            
            if multiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .lineLimit(2...4)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    // MARK: - Overall Notes Card
    
    private var overallNotesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Overall Notes", systemImage: "note.text")
                .font(.headline)
            
            TextEditor(text: $overallNotes)
                .font(.callout)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 80)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
    
    private func populateKREntries() {
        krEntries = objective.keyResults
            .sorted { $0.order < $1.order }
            .map { kr in
                let totalTasks = kr.tasks.count
                let completedTasks = kr.tasks.filter { $0.isCompleted }.count
                return KREntryDraft(
                    id: kr.id,
                    krTitle: kr.title,
                    keyResult: kr,
                    completedTasks: completedTasks,
                    totalTasks: totalTasks,
                    completionPercent: kr.progress * 100
                )
            }
    }
    
    private func updateCompletion(entry: Binding<KREntryDraft>) {
        let target = entry.wrappedValue.targetValue
        let current = entry.wrappedValue.currentValue
        if target > 0 {
            entry.wrappedValue.completionPercent = min((current / target) * 100, 100)
        }
    }
    
    private func saveReview() {
        isSaving = true
        
        let review = OKRReview(
            reviewType: reviewType,
            overallNotes: overallNotes
        )
        review.objective = objective
        modelContext.insert(review)
        
        for draft in krEntries {
            let entry = KRReviewEntry(
                currentValue: draft.currentValue,
                targetValue: draft.targetValue,
                completionPercent: draft.completionPercent,
                trend: draft.trend,
                status: draft.status,
                statusReason: draft.statusReason,
                progress: draft.progress,
                blockers: draft.blockers,
                nextSteps: draft.nextSteps,
                adjustmentNotes: draft.adjustmentNotes
            )
            entry.keyResult = draft.keyResult
            entry.review = review
            modelContext.insert(entry)
        }
        
        objective.lastReviewedAt = Date()
        objective.updatedAt = Date()
        dismiss()
    }
}
