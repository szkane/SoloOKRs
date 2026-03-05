// ReviewHistoryView.swift
// SoloOKRs
//
// Shows all past reviews for a given Objective, sorted by date.
// Redesigned 2026-03-05: Card-based layout with status chips.

import SwiftUI

struct ReviewHistoryView: View {
    @Environment(\.dismiss) private var dismiss
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
            }
        }
        .frame(minWidth: 520, minHeight: 400)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            
            Text("No Reviews Yet")
                .font(.title3.bold())
            
            Text("Create your first review to start\ntracking progress on this Objective.")
                .font(.subheadline)
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
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
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
                    .frame(width: 38, height: 38)
                Image(systemName: review.overallStatus?.icon ?? "questionmark.circle")
                    .foregroundStyle(review.overallStatus?.color ?? .gray)
                    .font(.system(size: 16))
            }
            
            // Center: Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(review.reviewType.rawValue)
                        .font(.subheadline.bold())
                    
                    if let status = review.overallStatus {
                        Text(status.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    if !review.krEntries.isEmpty {
                        // Mini status dots
                        HStack(spacing: 3) {
                            ForEach(review.krEntries.sorted(by: { ($0.keyResult?.order ?? 0) < ($1.keyResult?.order ?? 0) })) { entry in
                                Circle()
                                    .fill(entry.status.color)
                                    .frame(width: 6, height: 6)
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
