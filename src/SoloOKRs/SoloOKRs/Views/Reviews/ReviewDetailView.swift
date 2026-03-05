// ReviewDetailView.swift
// SoloOKRs
//
// Read-only display of a completed review with all KR entries.
// Redesigned 2026-03-05: Clear visual hierarchy with card-based KR entries.

import SwiftUI

struct ReviewDetailView: View {
    let review: OKRReview
    
    private var sortedEntries: [KRReviewEntry] {
        review.krEntries.sorted { ($0.keyResult?.order ?? 0) < ($1.keyResult?.order ?? 0) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerCard
                
                // Overall Notes
                if !review.overallNotes.isEmpty {
                    notesCard
                }
                
                // KR Entries
                if !sortedEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Key Results")
                            .font(.headline)
                            .padding(.leading, 4)
                        
                        ForEach(sortedEntries) { entry in
                            krCard(entry)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Review Detail")
    }
    
    // MARK: - Header
    
    private var headerCard: some View {
        HStack(spacing: 16) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: review.reviewType.icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(review.reviewType.displayName)
                    .font(.title3.bold())
                
                Text(review.createdAt.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let status = review.overallStatus {
                VStack(spacing: 2) {
                    Image(systemName: status.icon)
                        .font(.title2)
                        .foregroundStyle(status.color)
                    Text(status.displayName)
                        .font(.caption2.bold())
                        .foregroundStyle(status.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(status.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
    
    // MARK: - Notes
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Overall Notes", systemImage: "note.text")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            
            Text(review.overallNotes)
                .font(.callout)
                .textSelection(.enabled)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
    
    // MARK: - KR Card
    
    private func krCard(_ entry: KRReviewEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title + Status
            HStack {
                Text(entry.keyResult?.title ?? "Unknown KR")
                    .font(.system(.body, weight: .semibold))
                
                Spacer()
                
                Label { Text(entry.status.displayName) } icon: { Image(systemName: entry.status.icon) }
                    .font(.caption.bold())
                    .foregroundStyle(entry.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(entry.status.color.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Metrics row
            HStack(spacing: 0) {
                metricPill("Current", value: formatNumber(entry.currentValue))
                metricPill("Target", value: formatNumber(entry.targetValue))
                metricPill("Done", value: "\(Int(entry.completionPercent))%",
                          color: entry.status.color)
                
                HStack(spacing: 4) {
                    Image(systemName: entry.trend.icon)
                    Text(entry.trend.displayName)
                }
                .font(.caption.bold())
                .foregroundStyle(entry.trend.swiftUIColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(entry.trend.swiftUIColor.opacity(0.08))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
            }
            
            // Detail rows (only show non-empty)
            let details = detailItems(for: entry)
            if !details.isEmpty {
                Divider()
                
                VStack(spacing: 10) {
                    ForEach(details, id: \.label) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.icon)
                                .font(.caption)
                                .foregroundStyle(item.color)
                                .frame(width: 16)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.caption.bold())
                                    .foregroundStyle(item.color)
                                Text(item.text)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
    
    // MARK: - Helpers
    
    private func metricPill(_ label: LocalizedStringKey, value: String, color: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private struct DetailItem {
        let icon: String
        let label: String
        let text: String
        let color: Color
    }
    
    private func detailItems(for entry: KRReviewEntry) -> [DetailItem] {
        var items: [DetailItem] = []
        if !entry.statusReason.isEmpty {
            items.append(.init(icon: "info.circle", label: "Reason", text: entry.statusReason, color: .secondary))
        }
        if !entry.progress.isEmpty {
            items.append(.init(icon: "arrow.up.right.circle", label: "Progress", text: entry.progress, color: .green))
        }
        if !entry.blockers.isEmpty {
            items.append(.init(icon: "hand.raised.circle", label: "Blockers", text: entry.blockers, color: .red))
        }
        if !entry.nextSteps.isEmpty {
            items.append(.init(icon: "arrow.right.circle", label: "Next Steps", text: entry.nextSteps, color: .blue))
        }
        if !entry.adjustmentNotes.isEmpty {
            items.append(.init(icon: "slider.horizontal.3", label: "Adjustments", text: entry.adjustmentNotes, color: .orange))
        }
        return items
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
    
}
