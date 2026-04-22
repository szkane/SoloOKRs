// KeyResult.swift
// SoloOKRs
//
// Revised on 2026-02-06: Removed type fields; progress now based on task completion.

import Foundation
import SwiftData

@Model
final class KeyResult {
    var id: UUID = UUID()
    var title: String = ""
    var selfScore: Int?  // 0–100, set during Review Mode
    var order: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var objective: Objective?
    
    @Relationship(deleteRule: .cascade, inverse: \OKRTask.keyResult)
    var tasks: [OKRTask] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.selfScore = nil
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Progress is derived from task completion rate
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let completedCount = tasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(tasks.count)
    }
    
    /// Key Results follow parent Objective's editability
    @MainActor
    var isEditable: Bool {
        objective?.isEditable ?? true
    }
}
