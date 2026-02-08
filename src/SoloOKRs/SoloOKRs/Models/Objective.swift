// Objective.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import Foundation
import SwiftData

@Model
final class Objective {
    @Attribute(.unique) var id: UUID
    var title: String
    var objectiveDescription: String
    var startDate: Date
    var endDate: Date
    var status: OKRStatus
    var lastReviewedAt: Date?
    var archivedAt: Date?
    var order: Int
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \KeyResult.objective)
    var keyResults: [KeyResult] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        objectiveDescription: String = "",
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
        status: OKRStatus = .draft,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.objectiveDescription = objectiveDescription
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var progress: Double {
        guard !keyResults.isEmpty else { return 0 }
        return keyResults.reduce(0) { $0 + $1.progress } / Double(keyResults.count)
    }
    
    var isOverdue: Bool {
        endDate < Date() && status != .achieved && status != .archived
    }
    
    /// OKRs are only editable in Draft, or Active (if in Review Mode)
    @MainActor
    var isEditable: Bool {
        ReviewModeManager.shared.canEditOKR(status: status)
    }
}
