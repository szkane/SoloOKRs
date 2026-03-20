// MCPRouter.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.
// Expanded 2026-02-14: Full CRUD for Objectives, Key Results, and Tasks.

import Foundation
import SwiftData

/// Simple JSON-RPC request wrapper (populated from JSONSerialization)
struct JSONRPCRequest {
    let jsonrpc: String
    let method: String
    let params: [String: Any]?
    let id: Any?
    
    init?(from dict: [String: Any]) {
        guard let jsonrpc = dict["jsonrpc"] as? String,
              let method = dict["method"] as? String else { return nil }
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = dict["params"] as? [String: Any]
        self.id = dict["id"]
    }
}

@MainActor
class MCPRouter {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func handle(request: JSONRPCRequest) async -> [String: Any] {
        do {
            switch request.method {
            case "initialize":
                return success(id: request.id, result: [
                    "protocolVersion": "2024-11-05",
                    "capabilities": [
                        "tools": ["listChanged": true]
                    ],
                    "serverInfo": [
                        "name": "SoloOKRs",
                        "version": "1.0.0"
                    ]
                ])
                
            case "notifications/initialized":
                return success(id: request.id, result: "ok")
                
            case "tools/list":
                return success(id: request.id, result: ["tools": toolDefinitions()])
                
            case "tools/call":
                return try await handleToolCall(request)
                
            default:
                return error(id: request.id, code: -32601, message: "Method not found: \(request.method)")
            }
        } catch {
            return self.error(id: request.id, code: -32000, message: error.localizedDescription)
        }
    }
    
    // MARK: - Tool Definitions
    
    private func toolDefinitions() -> [[String: Any]] {
        [
            // Objectives
            makeTool(name: "list_objectives",
                     description: "List all OKR objectives with status, progress, review count, and last reviewed date.",
                     properties: [:], required: []),
            makeTool(name: "create_objective",
                     description: "Create a new OKR objective (defaults to Draft status).",
                     properties: [
                        "title": ["type": "string", "description": "Title of the objective"],
                        "description": ["type": "string", "description": "Detailed description"]
                     ], required: ["title"]),
            makeTool(name: "update_objective",
                     description: "Update an existing objective's fields.",
                     properties: [
                        "id": ["type": "string", "description": "UUID of the objective"],
                        "title": ["type": "string", "description": "New title"],
                        "description": ["type": "string", "description": "New description"],
                        "status": ["type": "string", "description": "New status: draft, active, review, achieved, archived"]
                     ], required: ["id"]),
            makeTool(name: "delete_objective",
                     description: "Archive an objective (soft delete).",
                     properties: [
                        "id": ["type": "string", "description": "UUID of the objective"]
                     ], required: ["id"]),
            
            // Key Results
            makeTool(name: "list_key_results",
                     description: "List key results for an objective.",
                     properties: [
                        "objective_id": ["type": "string", "description": "UUID of the parent objective"]
                     ], required: ["objective_id"]),
            makeTool(name: "create_key_result",
                     description: "Create a new key result under an objective.",
                     properties: [
                        "objective_id": ["type": "string", "description": "UUID of the parent objective"],
                        "title": ["type": "string", "description": "Title of the key result"]
                     ], required: ["objective_id", "title"]),
            makeTool(name: "update_key_result",
                     description: "Update an existing key result.",
                     properties: [
                        "id": ["type": "string", "description": "UUID of the key result"],
                        "title": ["type": "string", "description": "New title"],
                        "self_score": ["type": "integer", "description": "Self-assessment score 0-100"]
                     ], required: ["id"]),
            makeTool(name: "delete_key_result",
                     description: "Delete a key result.",
                     properties: [
                        "id": ["type": "string", "description": "UUID of the key result"]
                     ], required: ["id"]),
            
            // Tasks
            makeTool(name: "list_tasks",
                     description: "List tasks for a key result.",
                     properties: [
                        "key_result_id": ["type": "string", "description": "UUID of the parent key result"]
                     ], required: ["key_result_id"]),
            makeTool(name: "create_task",
                     description: "Create a new task under a key result.",
                     properties: [
                        "key_result_id": ["type": "string", "description": "UUID of the parent key result"],
                        "title": ["type": "string", "description": "Title of the task"],
                        "taskDescription": ["type": "string", "description": "Notes for the task. Supports GitHub-flavored Markdown (GFM): bold, italic, bullet lists, numbered lists, code blocks (fenced with ```), inline code, links, and blockquotes."],
                        "priority": ["type": "string", "description": "Priority: low, medium, high, urgent"]
                     ], required: ["key_result_id", "title"]),
            makeTool(name: "update_task",
                     description: "Update an existing task.",
                     properties: [
                        "id": ["type": "string", "description": "UUID of the task"],
                        "title": ["type": "string", "description": "New title"],
                        "taskDescription": ["type": "string", "description": "Updated notes for the task. Supports GitHub-flavored Markdown (GFM): bold, italic, bullet lists, numbered lists, code blocks (fenced with ```), inline code, links, and blockquotes."],
                        "is_completed": ["type": "boolean", "description": "Mark task as completed or not"],
                        "priority": ["type": "string", "description": "Priority: low, medium, high, urgent"]
                     ], required: ["id"]),
            makeTool(name: "delete_task",
                     description: "Delete a task.",
                     properties: [
                        "id": ["type": "string", "description": "UUID of the task"]
                     ], required: ["id"]),
            
            // Reviews
            makeTool(name: "list_reviews",
                     description: "List all reviews for a specific objective, ordered by most recent first.",
                     properties: [
                        "objective_id": ["type": "string", "description": "UUID of the objective"]
                     ], required: ["objective_id"]),
            makeTool(name: "get_review",
                     description: "Get full detail of a review including all KR entries (status, trend, progress, blockers, next steps).",
                     properties: [
                        "id": ["type": "string", "description": "UUID of the review"]
                     ], required: ["id"]),
            makeTool(name: "create_review",
                     description: "Create a new review for an objective. Optionally include per-KR entries as a JSON array string in kr_entries.",
                     properties: [
                        "objective_id": ["type": "string", "description": "UUID of the objective to review"],
                        "review_type": ["type": "string", "description": "Type: weekly, midCycle, endCycle (default: weekly)"],
                        "overall_notes": ["type": "string", "description": "Overall review notes and summary (supports Markdown)"],
                        "kr_entries": ["type": "string", "description": "JSON array string of KR entries. Each entry: {\"kr_id\": \"uuid\", \"status\": \"onTrack|atRisk|offTrack|blocked\", \"trend\": \"up|down|flat\", \"completion_percent\": 75, \"current_value\": 75, \"target_value\": 100, \"progress\": \"...\", \"blockers\": \"...\", \"next_steps\": \"...\", \"adjustment_notes\": \"...\", \"status_reason\": \"\"}.\"\"\""]
                     ], required: ["objective_id"]),
        ]
    }
    
    private func makeTool(name: String, description: String, properties: [String: [String: String]], required: [String]) -> [String: Any] {
        [
            "name": name,
            "description": description,
            "inputSchema": [
                "type": "object",
                "properties": properties,
                "required": required
            ] as [String: Any]
        ]
    }
    
    // MARK: - Tool Call Dispatch
    
    private func handleToolCall(_ request: JSONRPCRequest) async throws -> [String: Any] {
        guard let paramsDict = request.params,
              let name = paramsDict["name"] as? String else {
            return error(id: request.id, code: -32602, message: "Invalid params: missing tool name")
        }
        let arguments = paramsDict["arguments"] as? [String: Any] ?? [:]
        
        switch name {
        // Objectives
        case "list_objectives":     return try handleListObjectives(id: request.id)
        case "create_objective":    return try handleCreateObjective(id: request.id, args: arguments)
        case "update_objective":    return try handleUpdateObjective(id: request.id, args: arguments)
        case "delete_objective":    return try handleDeleteObjective(id: request.id, args: arguments)
        // Key Results
        case "list_key_results":    return try handleListKeyResults(id: request.id, args: arguments)
        case "create_key_result":   return try handleCreateKeyResult(id: request.id, args: arguments)
        case "update_key_result":   return try handleUpdateKeyResult(id: request.id, args: arguments)
        case "delete_key_result":   return try handleDeleteKeyResult(id: request.id, args: arguments)
        // Tasks
        case "list_tasks":          return try handleListTasks(id: request.id, args: arguments)
        case "create_task":         return try handleCreateTask(id: request.id, args: arguments)
        case "update_task":         return try handleUpdateTask(id: request.id, args: arguments)
        case "delete_task":         return try handleDeleteTask(id: request.id, args: arguments)
        // Reviews
        case "list_reviews":        return try handleListReviews(id: request.id, args: arguments)
        case "get_review":          return try handleGetReview(id: request.id, args: arguments)
        case "create_review":       return try handleCreateReview(id: request.id, args: arguments)
        default:
            return error(id: request.id, code: -32601, message: "Tool not found: \(name)")
        }
    }
    
    // MARK: - Objective Handlers
    
    private func handleListObjectives(id: Any?) throws -> [String: Any] {
        let descriptor = FetchDescriptor<Objective>(sortBy: [SortDescriptor(\.order)])
        let objectives = try modelContext.fetch(descriptor)
        let result = objectives.map { obj in
            var dict: [String: String] = [
                "id": obj.id.uuidString,
                "title": obj.title,
                "description": obj.objectiveDescription,
                "status": obj.status.rawValue,
                "progress": "\(Int(obj.progress * 100))%",
                "startDate": ISO8601DateFormatter().string(from: obj.startDate),
                "endDate": ISO8601DateFormatter().string(from: obj.endDate),
                "keyResultCount": "\(obj.keyResults.count)",
                "reviewCount": "\(obj.reviews.count)"
            ]
            if let lastReviewed = obj.lastReviewedAt {
                dict["lastReviewedAt"] = ISO8601DateFormatter().string(from: lastReviewed)
            } else {
                dict["lastReviewedAt"] = "never"
            }
            return dict
        }
        return textResult(id: id, result)
    }
    
    private func handleCreateObjective(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let title = args["title"] as? String else {
            return error(id: id, code: -32602, message: "Missing required parameter: title")
        }
        let desc = args["description"] as? String ?? ""
        
        let newObj = Objective(
            title: title,
            objectiveDescription: desc,
            status: .draft,
            order: 0
        )
        modelContext.insert(newObj)
        try modelContext.save()
        return textResult(id: id, "Created objective '\(title)' (id: \(newObj.id.uuidString)) in Draft status.")
    }
    
    private func handleUpdateObjective(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: id")
        }
        
        var descriptor = FetchDescriptor<Objective>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let obj = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Objective not found: \(idStr)")
        }
        
        var changes: [String] = []
        if let title = args["title"] as? String { obj.title = title; changes.append("title") }
        if let desc = args["description"] as? String { obj.objectiveDescription = desc; changes.append("description") }
        if let statusStr = args["status"] as? String, let status = OKRStatus(rawValue: statusStr) {
            obj.status = status; changes.append("status → \(status.rawValue)")
        }
        obj.updatedAt = Date()
        try modelContext.save()
        return textResult(id: id, "Updated objective '\(obj.title)': \(changes.joined(separator: ", "))")
    }
    
    private func handleDeleteObjective(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: id")
        }
        
        var descriptor = FetchDescriptor<Objective>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let obj = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Objective not found: \(idStr)")
        }
        
        obj.status = .archived
        obj.archivedAt = Date()
        obj.updatedAt = Date()
        try modelContext.save()
        return textResult(id: id, "Archived objective '\(obj.title)'.")
    }
    
    // MARK: - Key Result Handlers
    
    private func handleListKeyResults(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["objective_id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: objective_id")
        }
        
        var descriptor = FetchDescriptor<Objective>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let obj = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Objective not found: \(idStr)")
        }
        
        let result = obj.keyResults.sorted { $0.order < $1.order }.map { kr in
            [
                "id": kr.id.uuidString,
                "title": kr.title,
                "progress": "\(Int(kr.progress * 100))%",
                "selfScore": kr.selfScore.map { "\($0)" } ?? "not set",
                "taskCount": "\(kr.tasks.count)",
                "completedTaskCount": "\(kr.tasks.filter { $0.isCompleted }.count)"
            ]
        }
        return textResult(id: id, result)
    }
    
    private func handleCreateKeyResult(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["objective_id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: objective_id")
        }
        guard let title = args["title"] as? String else {
            return error(id: id, code: -32602, message: "Missing required parameter: title")
        }
        
        var descriptor = FetchDescriptor<Objective>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let obj = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Objective not found: \(idStr)")
        }
        
        let kr = KeyResult(title: title, order: obj.keyResults.count)
        kr.objective = obj
        modelContext.insert(kr)
        try modelContext.save()
        return textResult(id: id, "Created key result '\(title)' (id: \(kr.id.uuidString)) under '\(obj.title)'.")
    }
    
    private func handleUpdateKeyResult(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: id")
        }
        
        var descriptor = FetchDescriptor<KeyResult>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let kr = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Key result not found: \(idStr)")
        }
        
        var changes: [String] = []
        if let title = args["title"] as? String { kr.title = title; changes.append("title") }
        if let score = args["self_score"] as? Int { kr.selfScore = score; changes.append("selfScore → \(score)") }
        kr.updatedAt = Date()
        try modelContext.save()
        return textResult(id: id, "Updated key result '\(kr.title)': \(changes.joined(separator: ", "))")
    }
    
    private func handleDeleteKeyResult(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: id")
        }
        
        var descriptor = FetchDescriptor<KeyResult>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let kr = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Key result not found: \(idStr)")
        }
        
        let title = kr.title
        modelContext.delete(kr)
        try modelContext.save()
        return textResult(id: id, "Deleted key result '\(title)'.")
    }
    
    // MARK: - Task Handlers
    
    private func handleListTasks(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["key_result_id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: key_result_id")
        }
        
        var descriptor = FetchDescriptor<KeyResult>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let kr = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Key result not found: \(idStr)")
        }
        
        let result = kr.tasks.sorted { $0.order < $1.order }.map { task in
            [
                "id": task.id.uuidString,
                "title": task.title,
                "taskDescription": task.taskDescription,
                "taskDescription_format": "markdown",
                "isCompleted": task.isCompleted ? "true" : "false",
                "priority": "\(task.priority)",
                "dueDate": task.dueDate.map { ISO8601DateFormatter().string(from: $0) } ?? "not set"
            ]
        }
        return textResult(id: id, result)
    }
    
    private func handleCreateTask(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["key_result_id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: key_result_id")
        }
        guard let title = args["title"] as? String else {
            return error(id: id, code: -32602, message: "Missing required parameter: title")
        }
        
        var descriptor = FetchDescriptor<KeyResult>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let kr = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Key result not found: \(idStr)")
        }
        
        let desc = args["taskDescription"] as? String ?? args["description"] as? String ?? ""
        var priority = Priority.medium
        if let priStr = args["priority"] as? String {
            switch priStr.lowercased() {
            case "low": priority = .low
            case "high": priority = .high
            case "urgent": priority = .urgent
            default: priority = .medium
            }
        }
        
        let task = OKRTask(title: title, taskDescription: desc, priority: priority, order: kr.tasks.count)
        task.keyResult = kr
        modelContext.insert(task)
        try modelContext.save()
        return textResult(id: id, "Created task '\(title)' (id: \(task.id.uuidString)) under key result '\(kr.title)'.")
    }
    
    private func handleUpdateTask(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: id")
        }
        
        var descriptor = FetchDescriptor<OKRTask>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let task = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Task not found: \(idStr)")
        }
        
        var changes: [String] = []
        if let title = args["title"] as? String { task.title = title; changes.append("title") }
        if let desc = args["taskDescription"] as? String ?? args["description"] as? String {
            task.taskDescription = desc; changes.append("taskDescription")
        }
        if let completed = args["is_completed"] as? Bool { task.isCompleted = completed; changes.append("isCompleted → \(completed)") }
        if let priStr = args["priority"] as? String {
            switch priStr.lowercased() {
            case "low": task.priority = .low
            case "high": task.priority = .high
            case "urgent": task.priority = .urgent
            default: task.priority = .medium
            }
            changes.append("priority → \(priStr)")
        }
        task.updatedAt = Date()
        try modelContext.save()
        return textResult(id: id, "Updated task '\(task.title)': \(changes.joined(separator: ", "))")
    }
    
    private func handleDeleteTask(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: id")
        }
        
        var descriptor = FetchDescriptor<OKRTask>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let task = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Task not found: \(idStr)")
        }
        
        let title = task.title
        modelContext.delete(task)
        try modelContext.save()
        return textResult(id: id, "Deleted task '\(title)'.")
    }
    
    // MARK: - Review Handlers
    
    private func handleListReviews(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["objective_id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: objective_id")
        }
        
        var descriptor = FetchDescriptor<Objective>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let obj = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Objective not found: \(idStr)")
        }
        
        let formatter = ISO8601DateFormatter()
        let result = obj.reviews
            .sorted { $0.createdAt > $1.createdAt }
            .map { review in
                [
                    "id": review.id.uuidString,
                    "reviewType": review.reviewType.rawValue,
                    "createdAt": formatter.string(from: review.createdAt),
                    "overallStatus": review.overallStatus?.rawValue ?? "n/a",
                    "krEntryCount": "\(review.krEntries.count)",
                    "overallNotes": review.overallNotes.isEmpty ? "(none)" : review.overallNotes
                ]
            }
        return textResult(id: id, result.isEmpty ? [["info": "No reviews found for this objective."]] : result)
    }
    
    private func handleGetReview(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: id")
        }
        
        var descriptor = FetchDescriptor<OKRReview>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let review = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Review not found: \(idStr)")
        }
        
        let formatter = ISO8601DateFormatter()
        var lines: [String] = [
            "id: \(review.id.uuidString)",
            "reviewType: \(review.reviewType.rawValue)",
            "createdAt: \(formatter.string(from: review.createdAt))",
            "objectiveTitle: \(review.objective?.title ?? "unknown")",
            "overallStatus: \(review.overallStatus?.rawValue ?? "n/a")",
            "overallNotes: \(review.overallNotes.isEmpty ? "(none)" : review.overallNotes)",
            "",
            "KR Entries (\(review.krEntries.count)):"
        ]
        for entry in review.krEntries {
            lines.append("  - \(entry.keyResult?.title ?? "unknown KR")")
            lines.append("    status: \(entry.status.rawValue), trend: \(entry.trend.rawValue)")
            lines.append("    completion: \(Int(entry.completionPercent))% (\(Int(entry.currentValue))/\(Int(entry.targetValue)))")
            if !entry.progress.isEmpty    { lines.append("    progress: \(entry.progress)") }
            if !entry.blockers.isEmpty    { lines.append("    blockers: \(entry.blockers)") }
            if !entry.nextSteps.isEmpty   { lines.append("    nextSteps: \(entry.nextSteps)") }
            if !entry.statusReason.isEmpty { lines.append("    statusReason: \(entry.statusReason)") }
            if !entry.adjustmentNotes.isEmpty { lines.append("    adjustmentNotes: \(entry.adjustmentNotes)") }
        }
        return textResult(id: id, lines.joined(separator: "\n"))
    }
    
    private func handleCreateReview(id: Any?, args: [String: Any]) throws -> [String: Any] {
        guard let idStr = args["objective_id"] as? String, let uuid = UUID(uuidString: idStr) else {
            return error(id: id, code: -32602, message: "Missing or invalid parameter: objective_id")
        }
        
        var descriptor = FetchDescriptor<Objective>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        guard let obj = try modelContext.fetch(descriptor).first else {
            return error(id: id, code: -32602, message: "Objective not found: \(idStr)")
        }
        
        // Parse review type
        var reviewType = ReviewType.weekly
        if let typeStr = args["review_type"] as? String {
            reviewType = ReviewType(rawValue: typeStr) ?? .weekly
        }
        let overallNotes = args["overall_notes"] as? String ?? ""
        
        let review = OKRReview(reviewType: reviewType, overallNotes: overallNotes)
        review.objective = obj
        modelContext.insert(review)
        
        // Parse optional kr_entries JSON string
        var entryCount = 0
        if let krEntriesStr = args["kr_entries"] as? String,
           let data = krEntriesStr.data(using: .utf8),
           let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            
            for entryDict in entries {
                guard let krIdStr = entryDict["kr_id"] as? String,
                      let krUUID = UUID(uuidString: krIdStr) else { continue }
                
                var krDescriptor = FetchDescriptor<KeyResult>(predicate: #Predicate { $0.id == krUUID })
                krDescriptor.fetchLimit = 1
                guard let kr = try? modelContext.fetch(krDescriptor).first else { continue }
                
                let status = KRReviewStatus(rawValue: entryDict["status"] as? String ?? "onTrack") ?? .onTrack
                let trend  = ReviewTrend(rawValue: entryDict["trend"] as? String ?? "flat") ?? .flat
                let completionPercent = entryDict["completion_percent"] as? Double ?? 0
                let currentValue      = entryDict["current_value"] as? Double ?? 0
                let targetValue       = entryDict["target_value"] as? Double ?? 100
                
                let entry = KRReviewEntry(
                    currentValue: currentValue,
                    targetValue: targetValue,
                    completionPercent: completionPercent,
                    trend: trend,
                    status: status,
                    statusReason:     entryDict["status_reason"] as? String ?? "",
                    progress:         entryDict["progress"] as? String ?? "",
                    blockers:         entryDict["blockers"] as? String ?? "",
                    nextSteps:        entryDict["next_steps"] as? String ?? "",
                    adjustmentNotes:  entryDict["adjustment_notes"] as? String ?? ""
                )
                entry.keyResult = kr
                entry.review = review
                modelContext.insert(entry)
                entryCount += 1
            }
        }
        
        obj.lastReviewedAt = Date()
        obj.updatedAt = Date()
        try modelContext.save()
        
        return textResult(id: id, "Created \(reviewType.rawValue) review (id: \(review.id.uuidString)) for '\(obj.title)' with \(entryCount) KR entries.")
    }
    
    // MARK: - Helpers
    
    private func textResult(id: Any?, _ text: String) -> [String: Any] {
        success(id: id, result: ["content": [["type": "text", "text": text]]])
    }
    
    private func textResult(id: Any?, _ items: [[String: String]]) -> [String: Any] {
        let text = items.map { dict in
            dict.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        }.joined(separator: "\n")
        return success(id: id, result: ["content": [["type": "text", "text": items.isEmpty ? "No items found." : text]]])
    }
    
    private func success(id: Any?, result: Any) -> [String: Any] {
        var response: [String: Any] = ["jsonrpc": "2.0", "result": result]
        if let id = id { response["id"] = id }
        return response
    }
    
    private func error(id: Any?, code: Int, message: String) -> [String: Any] {
        var response: [String: Any] = ["jsonrpc": "2.0", "error": ["code": code, "message": message]]
        if let id = id { response["id"] = id }
        return response
    }
}
