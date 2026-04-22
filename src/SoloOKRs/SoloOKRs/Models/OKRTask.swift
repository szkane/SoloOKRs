// OKRTask.swift
// SoloOKRs
//
// Revised on 2026-02-13: Simplified task model — no types, no subtasks.

import Foundation
import SwiftData

@Model
final class OKRTask {
    var id: UUID = UUID()
    var title: String = ""
    var taskDescription: String = ""
    
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
        dueDate: Date? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        order: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
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
    
    /// Tasks are editable in Draft, Active, Review; only Achieved/Archived are read-only
    @MainActor
    var isEditable: Bool {
        ReviewModeManager.shared.canEditTask(self)
    }
}
