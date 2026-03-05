// ReviewHistoryView.swift
// SoloOKRs
//
// Shows all past reviews for a given Objective, sorted by date.
// Redesigned 2026-03-05: Card-based layout with status chips.

import SwiftUI

struct ReviewHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredLanguage") private var preferredLanguage = ""
    let objective: Objective
    @State private var showingCreateReview = false
    
    private var sortedReviews: [OKRReview] {
        objective.reviews.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if sortedReviews.isEmpty {
                        emptyState
                    } else {
                        // Summary header
                        headerCard
                        
                        ForEach(sortedReviews) { review in
                            NavigationLink {
                                ReviewDetailView(review: review)
                            } label: {
                                reviewCard(review)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("Reviews — \(objective.title)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingCreateReview = true
                    } label: {
                        Label("New Review", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingCreateReview) {
                CreateReviewView(objective: objective)
                    .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
            }
        }
        .frame(minWidth: 640, minHeight: 480)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) { // Increased spacing
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50)) // Increased font size
                .foregroundStyle(.tertiary)
            
            Text("Review History (\(objective.reviews.count))") // Changed text and font size
                .font(.title2.bold())
            
            Text("Create your first review to start\ntracking progress on this Objective.")
                .font(.body) // Increased font size
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingCreateReview = true
            } label: {
                Label("Create First Review", systemImage: "plus.circle")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        HStack(spacing: 20) {
            statBadge(
                "\(sortedReviews.count)",
                label: "Total Reviews",
                color: .blue
            )
            
            Divider()
                .frame(height: 30)
            
            if let latest = sortedReviews.first {
                statBadge(
                    latest.createdAt.formatted(.relative(presentation: .named)),
                    label: "Last Review",
                    color: .green
                )
            }
            
            Divider()
                .frame(height: 30)
            
            // Status distribution
            let onTrack = sortedReviews.first?.krEntries.filter { $0.status == .onTrack }.count ?? 0
            let total = sortedReviews.first?.krEntries.count ?? 0
            statBadge(
                total > 0 ? "\(onTrack)/\(total) KRs" : "—",
                label: "On Track (Latest)",
                color: .green
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
    
    private func statBadge(_ value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.body.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Review Card
    
    private func reviewCard(_ review: OKRReview) -> some View {
        HStack(spacing: 14) {
            // Left: Status icon
            ZStack {
                Circle()
                    .fill((review.overallStatus?.color ?? .gray).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: review.overallStatus?.icon ?? "questionmark.circle")
                    .foregroundStyle(review.overallStatus?.color ?? .gray)
                    .font(.system(size: 20))
            }
            
            // Center: Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(review.reviewType.displayName)
                        .font(.body.bold())
                    
                    if let status = review.overallStatus {
                        Text(status.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.color.opacity(0.12))
                            .foregroundStyle(status.color)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    Label(
                        review.createdAt.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if !review.krEntries.isEmpty {
                        // Mini status dots
                        HStack(spacing: 3) {
                            ForEach(review.krEntries.sorted(by: { ($0.keyResult?.order ?? 0) < ($1.keyResult?.order ?? 0) })) { entry in
                                Circle()
                                    .fill(entry.status.color)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .contentShape(Rectangle())
    }
}
