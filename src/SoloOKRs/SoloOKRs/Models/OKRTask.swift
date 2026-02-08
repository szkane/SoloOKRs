// OKRTask.swift (was Task.swift)
// SoloOKRs
//
// Revised on 2026-02-06: Added type fields migrated from KeyResult.

import Foundation
import SwiftData

@Model
final class OKRTask {
    var id: UUID
    var title: String
    var taskDescription: String = ""
    
    // Type-specific tracking (migrated from KeyResult)
    var type: TaskType = TaskType.simple
    var targetValue: Double?        // For .numeric type
    var currentValue: Double?       // For .percentage or .numeric type
    var milestones: [String] = []   // For .milestone type
    var completedMilestones: [Bool] = []
    
    var dueDate: Date?
    var priority: Priority = Priority.medium
    var isCompleted: Bool
    var order: Int
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    @Relationship(deleteRule: .nullify)
    var keyResult: KeyResult?
    
    init(
        title: String,
        taskDescription: String = "",
        type: TaskType = .simple,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        order: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.type = type
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && !isCompleted
    }
    
    /// Task progress based on type
    var progress: Double {
        switch type {
        case .simple:
            return isCompleted ? 1.0 : 0.0
        case .percentage:
            return (currentValue ?? 0) / 100.0
        case .numeric:
            guard let target = targetValue, target > 0 else { return 0 }
            return min((currentValue ?? 0) / target, 1.0)
        case .milestone:
            guard !completedMilestones.isEmpty else { return 0 }
            return Double(completedMilestones.filter { $0 }.count) / Double(completedMilestones.count)
        }
    }
    
    /// Tasks are editable in Draft, Active, Review; only Achieved/Archived are read-only
    @MainActor
    var isEditable: Bool {
        ReviewModeManager.shared.canEditTask(self)
    }
}
