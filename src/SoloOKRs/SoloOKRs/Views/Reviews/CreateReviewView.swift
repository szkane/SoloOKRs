// CreateReviewView.swift
// SoloOKRs
//
// Form to create a new review for a specific Objective.
// Redesigned 2026-03-05: Card-based layout with step-by-step flow.

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
                    // ─── Step 1: Review Type ───
                    reviewTypeCard
                    
                    // ─── Step 2: KR Entries ───
                    krEntriesSection
                    
                    // ─── Step 3: Overall Notes ───
                    overallNotesCard
                }
                .padding(20)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("New Review — \(objective.title)")
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
            // Auto-expand the first KR
            if let first = krEntries.first {
                expandedKR = first.id
            }
        }
    }
    
    // MARK: - Step 1: Review Type
    
    private var reviewTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Review Type", systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 8) {
                ForEach(ReviewType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            reviewType = type
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            Text(type.rawValue)
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
    
    // MARK: - Step 2: KR Entries
    
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
            // Header (always visible)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedKR = isExpanded ? nil : entry.wrappedValue.id
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: entry.wrappedValue.status.icon)
                        .foregroundStyle(entry.wrappedValue.status.color)
                        .font(.system(size: 16))
                    
                    Text(entry.wrappedValue.krTitle)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Quick metrics badge
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
                Divider()
                    .padding(.horizontal, 14)
                
                VStack(spacing: 16) {
                    // Row 1: Metrics + Status
                    metricsRow(entry: entry)
                    
                    Divider()
                    
                    // Row 2: Text fields (stacked)
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
            // Current Value
            metricField("Current", value: entry.currentValue)
                .onChange(of: entry.wrappedValue.currentValue) { _, _ in
                    updateCompletion(entry: entry)
                }
            
            // Target Value
            metricField("Target", value: entry.targetValue)
                .onChange(of: entry.wrappedValue.targetValue) { _, _ in
                    updateCompletion(entry: entry)
                }
            
            // Completion (read-only)
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
            
            Divider()
                .frame(height: 40)
            
            // Status picker
            VStack(spacing: 4) {
                Text("Status")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("", selection: entry.status) {
                    ForEach(KRReviewStatus.allCases, id: \.self) { s in
                        Label(s.rawValue, systemImage: s.icon).tag(s)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            
            // Trend picker
            VStack(spacing: 4) {
                Text("Trend")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("", selection: entry.trend) {
                    ForEach(ReviewTrend.allCases, id: \.self) { t in
                        Label(t.rawValue, systemImage: t.icon).tag(t)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
        }
    }
    
    private func metricField(_ label: String, value: Binding<Double>) -> some View {
        VStack(spacing: 4) {
            Text(label)
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
                color: .orange,
                multiline: false
            )
        }
    }
    
    private func compactTextField(
        icon: String,
        label: String,
        placeholder: String,
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
    
    // MARK: - Step 3: Overall Notes
    
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
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
    
    private func populateKREntries() {
        krEntries = objective.keyResults
            .sorted { $0.order < $1.order }
            .map { kr in
                KREntryDraft(
                    id: kr.id,
                    krTitle: kr.title,
                    keyResult: kr,
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
