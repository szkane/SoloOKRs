// KRReviewEntry.swift
// SoloOKRs
//
// Per-KR data within a review: status, progress, blockers, next steps, trend.

import Foundation
import SwiftData

@Model
final class KRReviewEntry {
    var id: UUID = UUID()
    var currentValue: Double = 0
    var targetValue: Double = 100
    var completionPercent: Double = 0
    var trend: ReviewTrend = ReviewTrend.flat
    var status: KRReviewStatus = KRReviewStatus.onTrack
    var statusReason: String = ""
    var progress: String = ""
    var blockers: String = ""
    var nextSteps: String = ""
    var adjustmentNotes: String = ""
    var createdAt: Date = Date()
    
    var keyResult: KeyResult?
    var review: OKRReview?
    
    init(
        id: UUID = UUID(),
        currentValue: Double = 0,
        targetValue: Double = 100,
        completionPercent: Double = 0,
        trend: ReviewTrend = .flat,
        status: KRReviewStatus = .onTrack,
        statusReason: String = "",
        progress: String = "",
        blockers: String = "",
        nextSteps: String = "",
        adjustmentNotes: String = ""
    ) {
        self.id = id
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.completionPercent = completionPercent
        self.trend = trend
        self.status = status
        self.statusReason = statusReason
        self.progress = progress
        self.blockers = blockers
        self.nextSteps = nextSteps
        self.adjustmentNotes = adjustmentNotes
        self.createdAt = Date()
    }
}
