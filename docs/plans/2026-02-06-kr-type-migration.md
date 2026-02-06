# KR Type Migration to Tasks

> **Status:** Draft  
> **Created:** 2026-02-06

## Summary

This document corrects a fundamental design flaw: **Key Result types** (percentage, numeric, milestone, binary) were incorrectly placed on `KeyResult`. They should instead belong to **`Task`**.

## Problem Statement

The original design had:

- `KeyResult.type: KeyResultType` (percentage, numeric, milestone, binary)
- `KeyResult.progress` calculated differently per type

**This is wrong because:**

1. Key Result progress should derive from **task completion rate** (completed tasks / total tasks).
2. KR "scoring" (0-100 points) happens during **Review Mode**, where users self-evaluate the KR quality—not from type-based calculation.
3. The type-based tracking (percentage, numeric, milestone, binary) is appropriate for **Tasks**, not Key Results.

## Proposed Changes

### 1. Remove from `KeyResult`:

- `type: KeyResultType`
- `targetValue`, `currentValue` (used for percentage/numeric)
- `milestones[]`, `completedMilestones[]` (used for milestone)
- `isCompleted` (used for binary)

### 2. Add to `KeyResult`:

- `selfScore: Int?` (0–100, set during Review Mode)
- **`progress` computed property:** `completedTasks.count / tasks.count` (task-based)

### 3. Add to `Task`:

- `type: TaskType` (move `KeyResultType` → rename to `TaskType`)
- Associated fields: `targetValue`, `currentValue`, `milestones`, etc.

### 4. Rename Enum:

- `KeyResultType.swift` → `TaskType.swift`
- Update all references.

## New Model Definitions

### KeyResult (Revised)

```swift
@Model
class KeyResult {
    var id: UUID
    var title: String
    var selfScore: Int?  // 0–100, set during Review Mode
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    var objective: Objective?
    @Relationship(deleteRule: .cascade)
    var tasks: [OKRTask]

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.isCompleted }.count) / Double(tasks.count)
    }
}
```

### Task (Revised)

```swift
@Model
class OKRTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var type: TaskType  // percentage, numeric, milestone, binary
    var targetValue: Double?
    var currentValue: Double?
    var milestones: [String]
    var completedMilestones: [Bool]
    var dueDate: Date?
    var priority: Priority
    var isCompleted: Bool  // For binary type OR general completion
    var order: Int
    ...
}
```

## Impact

| Component                 | Change Required                                        |
| ------------------------- | ------------------------------------------------------ |
| `KeyResult.swift`         | Remove type fields, add `selfScore`, update `progress` |
| `OKRTask.swift`           | Add `type: TaskType` and related fields                |
| `KeyResultType.swift`     | Rename to `TaskType.swift`                             |
| `EditKeyResultView.swift` | Simplify to show task completion + self-score          |
| `EditTaskView.swift`      | Add type-specific editing UI                           |
| `AddKeyResultView.swift`  | Remove type picker                                     |
| `AddTaskView.swift`       | Add type picker                                        |
| `KeyResultRowView`        | Update progress display                                |

## Verification Plan

1. Migrate model + enum
2. Update all views referencing `KeyResult.type`
3. Build and fix compile errors
4. Test creating/editing Key Results (should be simpler now)
5. Test creating/editing Tasks with different types
