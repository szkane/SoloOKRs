// OKRReview.swift
// SoloOKRs
//
// A review record for an Objective. Each Objective can have multiple reviews over time.

import Foundation
import SwiftData

@Model
final class OKRReview {
    @Attribute(.unique) var id: UUID
    var reviewType: ReviewType
    var overallNotes: String
    var createdAt: Date
    
    var objective: Objective?
    
    @Relationship(deleteRule: .cascade, inverse: \KRReviewEntry.review)
    var krEntries: [KRReviewEntry] = []
    
    init(
        id: UUID = UUID(),
        reviewType: ReviewType = .weekly,
        overallNotes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reviewType = reviewType
        self.overallNotes = overallNotes
        self.createdAt = createdAt
    }
    
    /// Summary status: worst status among all KR entries
    var overallStatus: KRReviewStatus? {
        guard !krEntries.isEmpty else { return nil }
        let priority: [KRReviewStatus] = [.blocked, .offTrack, .atRisk, .onTrack]
        for status in priority {
            if krEntries.contains(where: { $0.status == status }) {
                return status
            }
        }
        return .onTrack
    }
}
