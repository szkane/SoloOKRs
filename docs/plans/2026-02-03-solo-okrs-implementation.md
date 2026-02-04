# SOLO OKRs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS 26 app for personal OKR management with a 3-column interface, AI-powered suggestions, MCP integration, and iCloud sync.

**Architecture:** SwiftUI with NavigationSplitView for 3-column layout, SwiftData for persistence with CloudKit sync, embedded MCP server using Swift NIO, and pluggable AI providers using a protocol-based abstraction.

**Tech Stack:** SwiftUI (Liquid Glass), SwiftData + CloudKit, Swift NIO (MCP server), StoreKit 2 (IAP), Keychain (API keys storage)

**Design Document:** [2026-02-03-solo-okrs-design.md](file:///Users/kane/Code/SoloOKRs/docs/plans/2026-02-03-solo-okrs-design.md)

---

## Phase 1: Project Foundation

### Task 1.1: Create Xcode Project

**Goal:** Initialize the macOS app project with correct configuration.

**Step 1: Create new Xcode project**

Open Xcode and create a new project:

- Template: macOS → App
- Product Name: `SoloOKRs`
- Team: Your Apple Developer Team
- Organization Identifier: `com.yourcompany`
- Interface: SwiftUI
- Language: Swift
- Storage: None (we'll add SwiftData manually)
- ✅ Include Tests

**Step 2: Configure project settings**

In project settings:

- Deployment Target: macOS 26.0
- Bundle Identifier: `com.yourcompany.SoloOKRs`
- App Category: Productivity
- Enable: Hardened Runtime, App Sandbox
- Capabilities: iCloud (CloudKit), In-App Purchase

**Step 3: Create folder structure**

```
SoloOKRs/
├── Models/
│   └── Enums/
├── Views/
│   ├── Objectives/
│   ├── KeyResults/
│   ├── Tasks/
│   ├── AI/
│   ├── Settings/
│   └── Components/
├── Services/
│   ├── MCPServer/
│   ├── AIProvider/
│   └── Subscription/
├── Utilities/
└── Resources/
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: initialize Xcode project with folder structure"
```

---

### Task 1.2: Define Enums

**Files:**

- Create: `SoloOKRs/Models/Enums/OKRStatus.swift`
- Create: `SoloOKRs/Models/Enums/KeyResultType.swift`
- Create: `SoloOKRs/Models/Enums/Priority.swift`
- Create: `SoloOKRs/Models/Enums/SubscriptionStatus.swift`

**Step 1: Create OKRStatus enum**

```swift
// SoloOKRs/Models/Enums/OKRStatus.swift
import Foundation

enum OKRStatus: String, Codable, CaseIterable {
    case draft      // Not yet started
    case active     // Currently being worked on
    case review     // Pending review (important for regular OKR check-ins)
    case achieved   // Successfully completed
    case archived   // No longer relevant, kept for history

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .review: return "Review"
        case .achieved: return "Achieved"
        case .archived: return "Archived"
        }
    }

    var icon: String {
        switch self {
        case .draft: return "doc.badge.clock"
        case .active: return "play.circle"
        case .review: return "eye.circle"
        case .achieved: return "checkmark.seal"
        case .archived: return "archivebox"
        }
    }
}
```

**Step 2: Create KeyResultType enum**

```swift
// SoloOKRs/Models/Enums/KeyResultType.swift
import Foundation

enum KeyResultType: String, Codable, CaseIterable {
    case percentage  // 0-100% slider
    case numeric     // current/target values
    case milestone   // Binary checkpoints
    case binary      // Done or not done

    var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .numeric: return "Numeric Target"
        case .milestone: return "Milestones"
        case .binary: return "Yes/No"
        }
    }
}
```

**Step 3: Create Priority enum**

```swift
// SoloOKRs/Models/Enums/Priority.swift
import Foundation
import SwiftUI

enum Priority: Int, Codable, CaseIterable, Comparable {
    case low = 4
    case medium = 3
    case high = 2
    case urgent = 1

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle"
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

**Step 4: Create SubscriptionStatus enum**

```swift
// SoloOKRs/Models/Enums/SubscriptionStatus.swift
import Foundation

enum SubscriptionStatus: String, Codable {
    case trial       // Within trial limits
    case subscribed  // Purchased/subscribed
    case expired     // Subscription lapsed
}
```

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add enum types for OKR status, key result type, priority, and subscription"
```

---

### Task 1.3: Create SwiftData Models

**Files:**

- Create: `SoloOKRs/Models/Objective.swift`
- Create: `SoloOKRs/Models/KeyResult.swift`
- Create: `SoloOKRs/Models/Task.swift`

**Step 1: Create Objective model**

```swift
// SoloOKRs/Models/Objective.swift
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
}
```

**Step 2: Create KeyResult model**

```swift
// SoloOKRs/Models/KeyResult.swift
import Foundation
import SwiftData

@Model
final class KeyResult {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: KeyResultType
    var targetValue: Double?
    var currentValue: Double?
    var milestones: [String]
    var completedMilestones: [Bool]
    var isCompleted: Bool
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    var objective: Objective?

    @Relationship(deleteRule: .cascade, inverse: \Task.keyResult)
    var tasks: [Task] = []

    init(
        id: UUID = UUID(),
        title: String,
        type: KeyResultType = .percentage,
        targetValue: Double? = nil,
        currentValue: Double? = 0,
        milestones: [String] = [],
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.milestones = milestones
        self.completedMilestones = Array(repeating: false, count: milestones.count)
        self.isCompleted = false
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var progress: Double {
        switch type {
        case .percentage:
            return (currentValue ?? 0) / 100.0
        case .numeric:
            guard let target = targetValue, target > 0 else { return 0 }
            return min((currentValue ?? 0) / target, 1.0)
        case .milestone:
            guard !completedMilestones.isEmpty else { return 0 }
            return Double(completedMilestones.filter { $0 }.count) / Double(completedMilestones.count)
        case .binary:
            return isCompleted ? 1.0 : 0.0
        }
    }
}
```

**Step 3: Create Task model**

```swift
// SoloOKRs/Models/Task.swift
import Foundation
import SwiftData

@Model
final class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String  // Markdown content
    var dueDate: Date?
    var priority: Priority
    var isCompleted: Bool
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    var keyResult: KeyResult?

    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        dueDate: Date? = nil,
        priority: Priority = .medium,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = false
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && !isCompleted
    }
}
```

**Step 4: Build and verify no errors**

Run: `Cmd+B` in Xcode
Expected: Build succeeds with no errors

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SwiftData models for Objective, KeyResult, and Task"
```

---

### Task 1.4: Configure App Entry Point with SwiftData

**Files:**

- Modify: `SoloOKRs/SoloOKRsApp.swift`

**Step 1: Update app entry point**

```swift
// SoloOKRs/SoloOKRsApp.swift
import SwiftUI
import SwiftData

@main
struct SoloOKRsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Objective.self,
            KeyResult.self,
            Task.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // Enables CloudKit sync
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)

        #if os(macOS)
        Settings {
            Text("Settings placeholder")
        }
        #endif
    }
}
```

**Step 2: Build and verify**

Run: `Cmd+B` in Xcode
Expected: Build succeeds

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: configure SwiftData container with CloudKit sync"
```

---

## Phase 2: Core UI - 3-Column Layout

### Task 2.1: Create ContentView with NavigationSplitView

**Files:**

- Modify: `SoloOKRs/ContentView.swift`

**Step 1: Create 3-column layout**

```swift
// SoloOKRs/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Objective.order) private var objectives: [Objective]

    @State private var selectedObjective: Objective?
    @State private var selectedKeyResult: KeyResult?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Column 1: Objectives
            ObjectiveListView(
                objectives: objectives,
                selectedObjective: $selectedObjective,
                selectedKeyResult: $selectedKeyResult
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // Column 2: Key Results
            if let objective = selectedObjective {
                KeyResultListView(
                    objective: objective,
                    selectedKeyResult: $selectedKeyResult
                )
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            } else {
                ContentUnavailableView(
                    "Select an Objective",
                    systemImage: "target",
                    description: Text("Choose an objective to view its key results")
                )
            }
        } detail: {
            // Column 3: Tasks
            if let keyResult = selectedKeyResult {
                TaskListView(keyResult: keyResult)
            } else {
                ContentUnavailableView(
                    "Select a Key Result",
                    systemImage: "checklist",
                    description: Text("Choose a key result to view its tasks")
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Objective.self, KeyResult.self, Task.self], inMemory: true)
}
```

**Step 2: Build and verify**

Run: `Cmd+B` in Xcode
Expected: Build fails - missing ObjectiveListView, KeyResultListView, TaskListView (expected, we'll create them next)

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add NavigationSplitView 3-column layout"
```

---

### Task 2.2: Create ObjectiveListView

**Files:**

- Create: `SoloOKRs/Views/Objectives/ObjectiveListView.swift`
- Create: `SoloOKRs/Views/Objectives/ObjectiveRowView.swift`

**Step 1: Create ObjectiveListView**

```swift
// SoloOKRs/Views/Objectives/ObjectiveListView.swift
import SwiftUI
import SwiftData

struct ObjectiveListView: View {
    @Environment(\.modelContext) private var modelContext
    let objectives: [Objective]
    @Binding var selectedObjective: Objective?
    @Binding var selectedKeyResult: KeyResult?

    @State private var showingAddSheet = false

    var body: some View {
        List(selection: $selectedObjective) {
            ForEach(objectives) { objective in
                ObjectiveRowView(objective: objective)
                    .tag(objective)
            }
            .onDelete(perform: deleteObjectives)
        }
        .navigationTitle("Objectives")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Objective", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddObjectiveView()
        }
        .onChange(of: selectedObjective) { _, newValue in
            // Clear key result selection when objective changes
            selectedKeyResult = nil
        }
    }

    private func deleteObjectives(at offsets: IndexSet) {
        for index in offsets {
            let objective = objectives[index]
            if selectedObjective == objective {
                selectedObjective = nil
            }
            modelContext.delete(objective)
        }
    }
}

#Preview {
    ObjectiveListView(
        objectives: [],
        selectedObjective: .constant(nil),
        selectedKeyResult: .constant(nil)
    )
    .modelContainer(for: Objective.self, inMemory: true)
}
```

**Step 2: Create ObjectiveRowView**

```swift
// SoloOKRs/Views/Objectives/ObjectiveRowView.swift
import SwiftUI

struct ObjectiveRowView: View {
    let objective: Objective

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: objective.status.icon)
                    .foregroundStyle(statusColor)
                Text(objective.title)
                    .font(.headline)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                ProgressView(value: objective.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 100)

                Text("\(Int(objective.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(dateRangeText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch objective.status {
        case .draft: return .gray
        case .active: return .blue
        case .review: return .orange
        case .achieved: return .green
        case .archived: return .secondary
        }
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: objective.startDate)) - \(formatter.string(from: objective.endDate))"
    }
}

#Preview {
    ObjectiveRowView(objective: Objective(title: "Sample Objective"))
        .frame(width: 250)
        .padding()
}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add ObjectiveListView and ObjectiveRowView"
```

---

### Task 2.3: Create KeyResultListView

**Files:**

- Create: `SoloOKRs/Views/KeyResults/KeyResultListView.swift`
- Create: `SoloOKRs/Views/KeyResults/KeyResultRowView.swift`

**Step 1: Create KeyResultListView**

```swift
// SoloOKRs/Views/KeyResults/KeyResultListView.swift
import SwiftUI
import SwiftData

struct KeyResultListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var objective: Objective
    @Binding var selectedKeyResult: KeyResult?

    @State private var showingAddSheet = false

    var sortedKeyResults: [KeyResult] {
        objective.keyResults.sorted { $0.order < $1.order }
    }

    var body: some View {
        List(selection: $selectedKeyResult) {
            ForEach(sortedKeyResults) { keyResult in
                KeyResultRowView(keyResult: keyResult)
                    .tag(keyResult)
            }
            .onDelete(perform: deleteKeyResults)
        }
        .navigationTitle("Key Results")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Key Result", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddKeyResultView(objective: objective)
        }
    }

    private func deleteKeyResults(at offsets: IndexSet) {
        let sorted = sortedKeyResults
        for index in offsets {
            let keyResult = sorted[index]
            if selectedKeyResult == keyResult {
                selectedKeyResult = nil
            }
            modelContext.delete(keyResult)
        }
    }
}

#Preview {
    let objective = Objective(title: "Sample Objective")
    return KeyResultListView(
        objective: objective,
        selectedKeyResult: .constant(nil)
    )
    .modelContainer(for: [Objective.self, KeyResult.self], inMemory: true)
}
```

**Step 2: Create KeyResultRowView**

```swift
// SoloOKRs/Views/KeyResults/KeyResultRowView.swift
import SwiftUI

struct KeyResultRowView: View {
    let keyResult: KeyResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: typeIcon)
                    .foregroundStyle(.secondary)
                Text(keyResult.title)
                    .font(.headline)
                    .lineLimit(2)
            }

            progressView
        }
        .padding(.vertical, 4)
    }

    private var typeIcon: String {
        switch keyResult.type {
        case .percentage: return "percent"
        case .numeric: return "number"
        case .milestone: return "flag.checkered"
        case .binary: return "checkmark.circle"
        }
    }

    @ViewBuilder
    private var progressView: some View {
        switch keyResult.type {
        case .percentage:
            HStack {
                ProgressView(value: keyResult.progress)
                    .progressViewStyle(.linear)
                Text("\(Int(keyResult.currentValue ?? 0))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .numeric:
            HStack {
                ProgressView(value: keyResult.progress)
                    .progressViewStyle(.linear)
                Text("\(Int(keyResult.currentValue ?? 0)) / \(Int(keyResult.targetValue ?? 0))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .milestone:
            let completed = keyResult.completedMilestones.filter { $0 }.count
            let total = keyResult.milestones.count
            HStack {
                ProgressView(value: keyResult.progress)
                    .progressViewStyle(.linear)
                Text("\(completed) / \(total) milestones")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .binary:
            HStack {
                Image(systemName: keyResult.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(keyResult.isCompleted ? .green : .secondary)
                Text(keyResult.isCompleted ? "Completed" : "Not completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        KeyResultRowView(keyResult: KeyResult(title: "Percentage KR", type: .percentage, currentValue: 75))
        KeyResultRowView(keyResult: KeyResult(title: "Numeric KR", type: .numeric, targetValue: 100, currentValue: 35))
    }
    .frame(width: 300)
    .padding()
}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add KeyResultListView and KeyResultRowView"
```

---

### Task 2.4: Create TaskListView

**Files:**

- Create: `SoloOKRs/Views/Tasks/TaskListView.swift`
- Create: `SoloOKRs/Views/Tasks/TaskRowView.swift`

**Step 1: Create TaskListView**

```swift
// SoloOKRs/Views/Tasks/TaskListView.swift
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var keyResult: KeyResult

    @State private var showingAddSheet = false
    @State private var selectedTask: Task?

    var sortedTasks: [Task] {
        keyResult.tasks.sorted { task1, task2 in
            // Sort by: incomplete first, then by priority, then by order
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted
            }
            if task1.priority != task2.priority {
                return task1.priority < task2.priority  // Lower rawValue = higher priority
            }
            return task1.order < task2.order
        }
    }

    var body: some View {
        List(selection: $selectedTask) {
            ForEach(sortedTasks) { task in
                TaskRowView(task: task)
                    .tag(task)
            }
            .onDelete(perform: deleteTasks)
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTaskView(keyResult: keyResult)
        }
        .inspector(isPresented: Binding(
            get: { selectedTask != nil },
            set: { if !$0 { selectedTask = nil } }
        )) {
            if let task = selectedTask {
                TaskDetailView(task: task)
            }
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        let sorted = sortedTasks
        for index in offsets {
            let task = sorted[index]
            if selectedTask == task {
                selectedTask = nil
            }
            modelContext.delete(task)
        }
    }
}

#Preview {
    let keyResult = KeyResult(title: "Sample KR")
    return TaskListView(keyResult: keyResult)
        .modelContainer(for: [KeyResult.self, Task.self], inMemory: true)
}
```

**Step 2: Create TaskRowView**

```swift
// SoloOKRs/Views/Tasks/TaskRowView.swift
import SwiftUI

struct TaskRowView: View {
    @Bindable var task: Task

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    task.isCompleted.toggle()
                    task.updatedAt = Date()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        Label(dueDateText(dueDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }

                    Label(task.priority.displayName, systemImage: task.priority.icon)
                        .font(.caption)
                        .foregroundStyle(task.priority.color)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func dueDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        TaskRowView(task: Task(title: "Sample Task", dueDate: Date(), priority: .high))
        TaskRowView(task: Task(title: "Completed Task", priority: .low))
    }
    .frame(width: 400)
    .padding()
}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add TaskListView and TaskRowView"
```

---

### Task 2.5: Create Add/Edit Forms

**Files:**

- Create: `SoloOKRs/Views/Objectives/AddObjectiveView.swift`
- Create: `SoloOKRs/Views/KeyResults/AddKeyResultView.swift`
- Create: `SoloOKRs/Views/Tasks/AddTaskView.swift`
- Create: `SoloOKRs/Views/Tasks/TaskDetailView.swift`

**Step 1: Create AddObjectiveView**

```swift
// SoloOKRs/Views/Objectives/AddObjectiveView.swift
import SwiftUI
import SwiftData

struct AddObjectiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var status: OKRStatus = .draft

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Timeline") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(OKRStatus.allCases, id: \.self) { status in
                            Label(status.displayName, systemImage: status.icon)
                                .tag(status)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Objective")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addObjective()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }

    private func addObjective() {
        let objective = Objective(
            title: title,
            objectiveDescription: description,
            startDate: startDate,
            endDate: endDate,
            status: status
        )
        modelContext.insert(objective)
        dismiss()
    }
}

#Preview {
    AddObjectiveView()
        .modelContainer(for: Objective.self, inMemory: true)
}
```

**Step 2: Create AddKeyResultView**

```swift
// SoloOKRs/Views/KeyResults/AddKeyResultView.swift
import SwiftUI
import SwiftData

struct AddKeyResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let objective: Objective

    @State private var title = ""
    @State private var type: KeyResultType = .percentage
    @State private var targetValue: Double = 100
    @State private var milestones: [String] = []
    @State private var newMilestone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)

                    Picker("Type", selection: $type) {
                        ForEach(KeyResultType.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                }

                switch type {
                case .numeric:
                    Section("Target") {
                        HStack {
                            Text("Target Value")
                            Spacer()
                            TextField("", value: $targetValue, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }

                case .milestone:
                    Section("Milestones") {
                        ForEach(milestones.indices, id: \.self) { index in
                            HStack {
                                Text(milestones[index])
                                Spacer()
                                Button {
                                    milestones.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField("New milestone", text: $newMilestone)
                            Button {
                                if !newMilestone.isEmpty {
                                    milestones.append(newMilestone)
                                    newMilestone = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newMilestone.isEmpty)
                        }
                    }

                default:
                    EmptyView()
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Key Result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addKeyResult()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func addKeyResult() {
        let keyResult = KeyResult(
            title: title,
            type: type,
            targetValue: type == .numeric ? targetValue : nil,
            milestones: type == .milestone ? milestones : [],
            order: objective.keyResults.count
        )
        keyResult.objective = objective
        modelContext.insert(keyResult)
        dismiss()
    }
}

#Preview {
    AddKeyResultView(objective: Objective(title: "Sample"))
        .modelContainer(for: [Objective.self, KeyResult.self], inMemory: true)
}
```

**Step 3: Create AddTaskView**

```swift
// SoloOKRs/Views/Tasks/AddTaskView.swift
import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let keyResult: KeyResult

    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: Priority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description (Markdown)", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Label(priority.displayName, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }

    private func addTask() {
        let task = Task(
            title: title,
            taskDescription: description,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            order: keyResult.tasks.count
        )
        task.keyResult = keyResult
        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    AddTaskView(keyResult: KeyResult(title: "Sample KR"))
        .modelContainer(for: [KeyResult.self, Task.self], inMemory: true)
}
```

**Step 4: Create TaskDetailView**

```swift
// SoloOKRs/Views/Tasks/TaskDetailView.swift
import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: Task
    @State private var isEditingDescription = false

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $task.title)

                Picker("Priority", selection: $task.priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Label(priority.displayName, systemImage: priority.icon)
                            .tag(priority)
                    }
                }
            }

            Section("Due Date") {
                if let dueDate = Binding($task.dueDate) {
                    DatePicker("Due", selection: dueDate, displayedComponents: .date)
                    Button("Remove Due Date", role: .destructive) {
                        task.dueDate = nil
                    }
                } else {
                    Button("Add Due Date") {
                        task.dueDate = Date()
                    }
                }
            }

            Section("Description") {
                if isEditingDescription {
                    TextEditor(text: $task.taskDescription)
                        .frame(minHeight: 150)
                        .font(.body.monospaced())
                } else {
                    Text(task.taskDescription.isEmpty ? "No description" : task.taskDescription)
                        .foregroundStyle(task.taskDescription.isEmpty ? .secondary : .primary)
                        .frame(minHeight: 100, alignment: .topLeading)
                }

                Toggle("Edit Markdown", isOn: $isEditingDescription)
            }

            Section("Status") {
                Toggle("Completed", isOn: $task.isCompleted)
            }
        }
        .formStyle(.grouped)
        .inspectorColumnWidth(min: 300, ideal: 350, max: 500)
        .onChange(of: task.title) { _, _ in
            task.updatedAt = Date()
        }
        .onChange(of: task.taskDescription) { _, _ in
            task.updatedAt = Date()
        }
    }
}

#Preview {
    TaskDetailView(task: Task(title: "Sample Task", taskDescription: "# Description\n\nThis is a **markdown** description."))
        .frame(width: 350)
}
```

**Step 5: Build and Run**

Run: `Cmd+R` in Xcode
Expected: App launches with 3-column layout. You can add objectives, key results, and tasks.

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add forms for creating objectives, key results, and tasks"
```

---

## Phase 3: Settings Window

### Task 3.1: Create Settings TabView

**Files:**

- Create: `SoloOKRs/Views/Settings/SettingsView.swift`
- Create: `SoloOKRs/Views/Settings/GeneralSettingsView.swift`
- Modify: `SoloOKRs/SoloOKRsApp.swift`

**Step 1: Create SettingsView**

```swift
// SoloOKRs/Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AIProviderSettingsView()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }

            MCPSettingsView()
                .tabItem {
                    Label("MCP", systemImage: "network")
                }

            SyncSettingsView()
                .tabItem {
                    Label("Sync", systemImage: "icloud")
                }

            SubscriptionSettingsView()
                .tabItem {
                    Label("Subscription", systemImage: "creditcard")
                }
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingsView()
}
```

**Step 2: Create GeneralSettingsView**

```swift
// SoloOKRs/Views/Settings/GeneralSettingsView.swift
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @AppStorage("defaultView") private var defaultView = "objectives"

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
            }

            Section("Default View") {
                Picker("Focus on Launch", selection: $defaultView) {
                    Text("Objectives").tag("objectives")
                    Text("Key Results").tag("keyresults")
                    Text("Tasks").tag("tasks")
                }
                .pickerStyle(.radioGroup)
            }

            Section("Appearance") {
                Text("Theme follows system settings")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

#Preview {
    GeneralSettingsView()
}
```

**Step 3: Create placeholder views**

```swift
// SoloOKRs/Views/Settings/AIProviderSettingsView.swift
import SwiftUI

struct AIProviderSettingsView: View {
    var body: some View {
        Form {
            Section("AI Provider") {
                Text("AI provider configuration coming soon...")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("AI Providers")
    }
}

// SoloOKRs/Views/Settings/MCPSettingsView.swift
import SwiftUI

struct MCPSettingsView: View {
    @AppStorage("mcpEnabled") private var mcpEnabled = true
    @AppStorage("mcpPort") private var mcpPort = 5100

    var body: some View {
        Form {
            Section("MCP Server") {
                Toggle("Enable MCP Server", isOn: $mcpEnabled)

                HStack {
                    Text("Port")
                    Spacer()
                    TextField("", value: $mcpPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }

            Section("Status") {
                HStack {
                    Circle()
                        .fill(mcpEnabled ? .green : .gray)
                        .frame(width: 10, height: 10)
                    Text(mcpEnabled ? "Running on localhost:\(mcpPort)" : "Stopped")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("MCP Server")
    }
}

// SoloOKRs/Views/Settings/SyncSettingsView.swift
import SwiftUI

struct SyncSettingsView: View {
    var body: some View {
        Form {
            Section("iCloud Sync") {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                    Text("Synced")
                }

                Text("Changes sync automatically via iCloud")
                    .foregroundStyle(.secondary)
            }

            Section("Actions") {
                Button("Sync Now") {
                    // Manual sync trigger
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Sync")
    }
}

// SoloOKRs/Views/Settings/SubscriptionSettingsView.swift
import SwiftUI

struct SubscriptionSettingsView: View {
    var body: some View {
        Form {
            Section("Current Plan") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text("Trial")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Objectives Used")
                    Spacer()
                    Text("0 / 3")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Upgrade") {
                Button("Upgrade to Pro") {
                    // Show paywall
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Restore") {
                Button("Restore Purchases") {
                    // Restore purchases
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Subscription")
    }
}
```

**Step 4: Update SoloOKRsApp.swift**

```swift
// Update the Settings scene in SoloOKRsApp.swift
#if os(macOS)
Settings {
    SettingsView()
}
#endif
```

**Step 5: Build and Run**

Run: `Cmd+R` then `Cmd+,` (Settings shortcut)
Expected: Settings window opens with 5 tabs

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add Settings window with tabs for General, AI, MCP, Sync, Subscription"
```

---

## Phase 4: AI Provider Integration (Placeholder)

> **Note:** Full AI integration requires API implementations. This task creates the protocol and placeholder structure.

### Task 4.1: Create AI Provider Protocol

**Files:**

- Create: `SoloOKRs/Services/AIProvider/AIProvider.swift`
- Create: `SoloOKRs/Services/AIProvider/AIService.swift`

**Step 1: Create AIProvider protocol**

```swift
// SoloOKRs/Services/AIProvider/AIProvider.swift
import Foundation

enum AIProviderType: String, CaseIterable, Codable {
    case gemini = "Gemini"
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case ollama = "Ollama"
    case lmstudio = "LM Studio"
    case custom = "Custom"
}

protocol AIProvider {
    var name: String { get }
    var type: AIProviderType { get }
    var isConfigured: Bool { get }

    func complete(prompt: String, systemPrompt: String?) async throws -> String
}

enum AIError: LocalizedError {
    case notConfigured
    case networkError(Error)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI provider is not configured. Please add your API key in Settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI provider."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
```

**Step 2: Create AIService**

```swift
// SoloOKRs/Services/AIProvider/AIService.swift
import Foundation
import SwiftUI

@Observable
@MainActor
class AIService {
    static let shared = AIService()

    var selectedProviderType: AIProviderType = .gemini
    var isProcessing = false
    var lastError: AIError?

    private init() {}

    var isConfigured: Bool {
        // Check if current provider has API key
        switch selectedProviderType {
        case .gemini:
            return !geminiAPIKey.isEmpty
        case .openai:
            return !openAIAPIKey.isEmpty
        case .anthropic:
            return !anthropicAPIKey.isEmpty
        case .ollama, .lmstudio:
            return true  // Local providers don't need API key
        case .custom:
            return !customEndpoint.isEmpty
        }
    }

    // API Keys (would be stored in Keychain in production)
    @AppStorage("geminiAPIKey") var geminiAPIKey = ""
    @AppStorage("openAIAPIKey") var openAIAPIKey = ""
    @AppStorage("anthropicAPIKey") var anthropicAPIKey = ""
    @AppStorage("ollamaEndpoint") var ollamaEndpoint = "http://localhost:11434"
    @AppStorage("lmStudioEndpoint") var lmStudioEndpoint = "http://localhost:1234"
    @AppStorage("customEndpoint") var customEndpoint = ""

    func analyzeOKR(_ objective: Objective) async throws -> String {
        guard isConfigured else {
            throw AIError.notConfigured
        }

        isProcessing = true
        defer { isProcessing = false }

        // Placeholder - actual implementation would call the selected provider
        try await Task.sleep(for: .seconds(1))

        return """
        ## OKR Analysis for "\(objective.title)"

        ✅ **Strengths:**
        - Clear objective statement
        - Defined timeline

        💡 **Suggestions:**
        - Consider adding more measurable key results
        - Review progress weekly

        This is a placeholder response. Configure your AI provider for real analysis.
        """
    }

    func suggestKeyResults(for objective: Objective) async throws -> [String] {
        guard isConfigured else {
            throw AIError.notConfigured
        }

        isProcessing = true
        defer { isProcessing = false }

        // Placeholder
        try await Task.sleep(for: .seconds(1))

        return [
            "Increase metric X by 20%",
            "Complete 5 key deliverables",
            "Achieve customer satisfaction score of 4.5+"
        ]
    }

    func suggestTasks(for keyResult: KeyResult) async throws -> [String] {
        guard isConfigured else {
            throw AIError.notConfigured
        }

        isProcessing = true
        defer { isProcessing = false }

        // Placeholder
        try await Task.sleep(for: .seconds(1))

        return [
            "Research and analyze current state",
            "Create action plan document",
            "Schedule stakeholder meetings",
            "Implement first milestone"
        ]
    }
}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add AI provider protocol and service placeholder"
```

---

## Phase 5: MCP Server (Placeholder)

> **Note:** Full MCP implementation requires Swift NIO/Vapor. This creates the structure.

### Task 5.1: Create MCP Server Structure

**Files:**

- Create: `SoloOKRs/Services/MCPServer/MCPServer.swift`

**Step 1: Create MCPServer placeholder**

```swift
// SoloOKRs/Services/MCPServer/MCPServer.swift
import Foundation
import SwiftUI

@Observable
@MainActor
class MCPServer {
    static let shared = MCPServer()

    var isRunning = false
    var port: Int = 5100
    var connectedClients: Int = 0

    private init() {}

    func start() async {
        guard !isRunning else { return }

        // Placeholder - actual implementation would start HTTP server
        isRunning = true
        print("MCP Server started on port \(port)")
    }

    func stop() {
        guard isRunning else { return }

        // Placeholder - actual implementation would stop HTTP server
        isRunning = false
        print("MCP Server stopped")
    }

    var statusText: String {
        if isRunning {
            return "Running on localhost:\(port)"
        } else {
            return "Stopped"
        }
    }
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add MCP server placeholder structure"
```

---

## Phase 6: Subscription Management (Placeholder)

### Task 6.1: Create Subscription Manager

**Files:**

- Create: `SoloOKRs/Services/Subscription/SubscriptionManager.swift`

**Step 1: Create SubscriptionManager**

```swift
// SoloOKRs/Services/Subscription/SubscriptionManager.swift
import Foundation
import SwiftUI
import StoreKit

@Observable
@MainActor
class SubscriptionManager {
    static let shared = SubscriptionManager()

    var subscriptionStatus: SubscriptionStatus = .trial
    var objectivesCreated: Int = 0

    private let maxTrialObjectives = 3

    private init() {
        // Load saved state
        objectivesCreated = UserDefaults.standard.integer(forKey: "objectivesCreated")
    }

    var canCreateObjective: Bool {
        subscriptionStatus == .subscribed || objectivesCreated < maxTrialObjectives
    }

    var remainingTrialObjectives: Int {
        max(0, maxTrialObjectives - objectivesCreated)
    }

    func incrementObjectiveCount() {
        objectivesCreated += 1
        UserDefaults.standard.set(objectivesCreated, forKey: "objectivesCreated")
    }

    func decrementObjectiveCount() {
        objectivesCreated = max(0, objectivesCreated - 1)
        UserDefaults.standard.set(objectivesCreated, forKey: "objectivesCreated")
    }

    func purchase() async throws {
        // Placeholder - actual implementation would use StoreKit 2
        subscriptionStatus = .subscribed
    }

    func restorePurchases() async throws {
        // Placeholder - actual implementation would restore via StoreKit 2
    }
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add subscription manager with trial logic"
```

---

## Phase 7: Polish & Testing

### Task 7.1: Add Liquid Glass Effects (macOS 26+)

**Files:**

- Modify: `SoloOKRs/ContentView.swift`
- Modify: Various view files

**Step 1: Update ContentView with Liquid Glass**

Add to ContentView.swift toolbar:

```swift
.toolbar {
    ToolbarItem(placement: .automatic) {
        HStack {
            // AI Status
            if AIService.shared.isConfigured {
                Label("AI Ready", systemImage: "brain")
                    .foregroundStyle(.green)
            }

            // MCP Status
            if MCPServer.shared.isRunning {
                Label("MCP", systemImage: "network")
                    .foregroundStyle(.green)
            }

            // Sync Status
            Label("Synced", systemImage: "icloud.fill")
                .foregroundStyle(.green)
        }
        .font(.caption)
    }
}
```

**Step 2: Build and verify Liquid Glass renders**

Run: `Cmd+R`
Expected: Sidebar and toolbar show translucent glass effect on macOS 26

**Step 3: Commit**

```bash
git add -A
git commit -m "style: add Liquid Glass effects and status bar indicators"
```

---

### Task 7.2: Final Testing Checklist

**Manual Testing:**

1. **Create Objective**
   - Click + in Objectives column
   - Fill form, click Add
   - ✅ Objective appears in list

2. **Create Key Result**
   - Select an objective
   - Click + in Key Results column
   - Test each KR type (Percentage, Numeric, Milestone, Binary)
   - ✅ KR appears with correct progress display

3. **Create Task**
   - Select a Key Result
   - Click + in Tasks column
   - Add due date and priority
   - ✅ Task appears sorted by priority

4. **Toggle Task Completion**
   - Click checkbox on task
   - ✅ Task shows strikethrough and moves to bottom

5. **Settings**
   - Press Cmd+,
   - ✅ Settings window opens with 5 tabs
   - ✅ Each tab displays content

6. **Delete Items**
   - Swipe or right-click to delete
   - ✅ Items are removed
   - ✅ Cascading deletes work (deleting Objective removes its KRs and Tasks)

7. **Window Resize**
   - Resize window
   - ✅ 3-column layout adjusts appropriately
   - ✅ Minimum window size enforced

---

## Verification Plan

### Automated Tests

> **Note:** SwiftUI testing is limited. Focus on unit tests for models and services.

Run tests with: `Cmd+U` in Xcode

### Manual Verification

Follow the testing checklist in Task 7.2 above.

### User Manual Testing

After implementation, deploy TestFlight build and have user verify:

1. Basic OKR workflow (create objective → KR → task)
2. Settings access via Cmd+,
3. iCloud sync between devices (if multiple devices available)
4. Review mode functionality
5. Archive functionality
6. Language switching

---

## Phase 8: Multilingual Support

### Task 8.1: Set Up Localization

**Files:**

- Create: `SoloOKRs/Resources/Localizable.xcstrings`
- Modify: Project settings for localization

**Step 1: Enable localization in Xcode**

1. Select project in navigator
2. Go to Info tab → Localizations
3. Click + and add:
   - English (Base)
   - Chinese (Simplified) - zh-Hans
   - German - de
   - French - fr
   - Spanish - es
   - Portuguese (Brazil) - pt-BR

**Step 2: Create String Catalog**

Create `Localizable.xcstrings` with translations for:

- All UI labels
- Button titles
- Status names (Draft, Active, Review, etc.)
- Priority names
- Error messages

**Step 3: Add language preference to GeneralSettingsView**

```swift
// Add to GeneralSettingsView
@AppStorage("preferredLanguage") private var preferredLanguage = ""

Section("Language") {
    Picker("App Language", selection: $preferredLanguage) {
        Text("System Default").tag("")
        Divider()
        Text("English").tag("en")
        Text("简体中文").tag("zh-Hans")
        Text("Deutsch").tag("de")
        Text("Français").tag("fr")
        Text("Español").tag("es")
        Text("Português").tag("pt-BR")
        // ... other languages
    }
}
```

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add multilingual support with English and high-priority languages"
```

---

## Phase 9: Edit Permissions & Review Mode

### Task 9.1: Add Review Mode State

**Files:**

- Create: `SoloOKRs/Services/ReviewModeManager.swift`
- Create: `SoloOKRs/Models/Enums/ReviewFrequency.swift`

**Step 1: Create ReviewFrequency enum**

```swift
// SoloOKRs/Models/Enums/ReviewFrequency.swift
import Foundation

enum ReviewFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
}
```

**Step 2: Create ReviewModeManager**

```swift
// SoloOKRs/Services/ReviewModeManager.swift
import Foundation
import SwiftUI

@Observable
@MainActor
class ReviewModeManager {
    static let shared = ReviewModeManager()

    @AppStorage("isInReviewMode") private var _isInReviewMode = false
    @AppStorage("reviewEnabled") var reviewEnabled = true
    @AppStorage("reviewFrequency") var frequency: ReviewFrequency = .weekly
    @AppStorage("reviewDayOfWeek") var dayOfWeek: Int = 1  // Monday
    @AppStorage("reviewHour") var reminderHour: Int = 9
    @AppStorage("reviewMinute") var reminderMinute: Int = 0

    var isInReviewMode: Bool {
        get { _isInReviewMode }
        set { _isInReviewMode = newValue }
    }

    private init() {}

    func enterReviewMode() {
        isInReviewMode = true
    }

    func exitReviewMode() {
        isInReviewMode = false
    }

    /// Check if an Objective/KeyResult can be edited
    func canEditOKR(status: OKRStatus) -> Bool {
        switch status {
        case .draft:
            return true
        case .active:
            return isInReviewMode  // Only editable in review mode
        case .review:
            return true
        case .achieved, .archived:
            return false
        }
    }

    /// Check if a Task can be edited (Tasks are read-only when Achieved or Archived)
    func canEditTask(parentStatus: OKRStatus) -> Bool {
        switch parentStatus {
        case .draft, .active, .review:
            return true  // Tasks always editable in these states
        case .achieved, .archived:
            return false  // Tasks read-only when parent Objective is Achieved/Archived
        }
    }
}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add ReviewModeManager for edit permissions"
```

---

### Task 9.2: Add Review Mode UI Indicators

**Files:**

- Modify: `SoloOKRs/ContentView.swift`
- Modify: `SoloOKRs/Views/Objectives/ObjectiveRowView.swift`
- Create: `SoloOKRs/Views/Settings/ReviewSettingsView.swift`

**Step 1: Add review mode indicator to ContentView toolbar**

```swift
// Add to ContentView toolbar
@State private var reviewManager = ReviewModeManager.shared

// In toolbar
if reviewManager.isInReviewMode {
    Button {
        reviewManager.exitReviewMode()
    } label: {
        Label("Review Mode", systemImage: "pencil.circle.fill")
            .foregroundStyle(.orange)
    }
    .help("Click to exit Review Mode")
} else {
    Button {
        reviewManager.enterReviewMode()
    } label: {
        Label("Enter Review", systemImage: "pencil.circle")
    }
}
```

**Step 2: Create ReviewSettingsView**

```swift
// SoloOKRs/Views/Settings/ReviewSettingsView.swift
import SwiftUI

struct ReviewSettingsView: View {
    @State private var reviewManager = ReviewModeManager.shared

    var body: some View {
        Form {
            Section("Review Schedule") {
                Toggle("Enable Review Reminders", isOn: $reviewManager.reviewEnabled)

                if reviewManager.reviewEnabled {
                    Picker("Frequency", selection: $reviewManager.frequency) {
                        ForEach(ReviewFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    Picker("Day", selection: $reviewManager.dayOfWeek) {
                        Text("Monday").tag(1)
                        Text("Tuesday").tag(2)
                        Text("Wednesday").tag(3)
                        Text("Thursday").tag(4)
                        Text("Friday").tag(5)
                        Text("Saturday").tag(6)
                        Text("Sunday").tag(7)
                    }

                    HStack {
                        Text("Time")
                        Spacer()
                        Text("\(reviewManager.reminderHour):\(String(format: "%02d", reviewManager.reminderMinute))")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Review Mode") {
                if reviewManager.isInReviewMode {
                    HStack {
                        Circle().fill(.orange).frame(width: 10, height: 10)
                        Text("Review Mode Active")
                    }
                    Button("Exit Review Mode") {
                        reviewManager.exitReviewMode()
                    }
                    .foregroundStyle(.orange)
                } else {
                    HStack {
                        Circle().fill(.gray).frame(width: 10, height: 10)
                        Text("Normal Mode")
                    }
                    Button("Enter Review Mode") {
                        reviewManager.enterReviewMode()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Review")
    }
}
```

**Step 3: Disable edit controls when not editable**

Update views to check permissions before allowing edits:

- **ObjectiveDetailView / KeyResultDetailView**: Use `ReviewModeManager.shared.canEditOKR(status:)` to disable form fields when not editable
- **TaskListView / TaskDetailView**: Use `ReviewModeManager.shared.canEditTask(parentStatus:)` to make tasks read-only when parent Objective is Achieved or Archived

```swift
// Example in TaskRowView
Button {
    // Toggle completion
} label: {
    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
}
.disabled(!ReviewModeManager.shared.canEditTask(parentStatus: task.keyResult?.objective?.status ?? .draft))
```

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add Review Mode UI and settings"
```

---

## Phase 10: Archiving (No Deletion for OKRs)

### Task 10.1: Update ObjectiveListView for Archive-Only

**Files:**

- Modify: `SoloOKRs/Views/Objectives/ObjectiveListView.swift`
- Modify: `SoloOKRs/ContentView.swift`

**Step 1: Replace delete with archive**

```swift
// In ObjectiveListView - replace onDelete with context menu
ForEach(objectives) { objective in
    ObjectiveRowView(objective: objective)
        .tag(objective)
        .contextMenu {
            if objective.status == .archived {
                Button("Unarchive") {
                    objective.status = .draft
                    objective.updatedAt = Date()
                }
            } else {
                Button("Archive", role: .destructive) {
                    archiveObjective(objective)
                }
            }
        }
}
// Remove .onDelete(perform:)
```

**Step 2: Add archive function**

```swift
private func archiveObjective(_ objective: Objective) {
    withAnimation {
        objective.status = .archived
        objective.archivedAt = Date()
        objective.updatedAt = Date()
        if selectedObjective == objective {
            selectedObjective = nil
        }
    }
}
```

**Step 3: Add Active/Archived tab picker**

```swift
// Add to ObjectiveListView
enum ObjectiveTab: String, CaseIterable {
    case active = "Active"
    case archived = "Archived"
}

@State private var selectedTab: ObjectiveTab = .active

var filteredObjectives: [Objective] {
    switch selectedTab {
    case .active:
        return objectives.filter { $0.status != .archived }
    case .archived:
        return objectives.filter { $0.status == .archived }
    }
}

// In body, add picker above list
Picker("", selection: $selectedTab) {
    ForEach(ObjectiveTab.allCases, id: \.self) { tab in
        Text(tab.rawValue)
    }
}
.pickerStyle(.segmented)
.padding(.horizontal)
```

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: replace delete with archive for OKRs"
```

---

### Task 10.2: Update Objective Model

**Files:**

- Modify: `SoloOKRs/Models/Objective.swift`

**Step 1: Add archivedAt property**

```swift
// Add to Objective model
var archivedAt: Date?

/// OKRs are only editable in Draft or Review states
var isEditable: Bool {
    status == .draft || status == .review
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add archivedAt and isEditable to Objective model"
```

---

## Summary

| Phase           | Tasks                                   | Status |
| --------------- | --------------------------------------- | ------ |
| 1. Foundation   | Project setup, enums, models, SwiftData | ⬜     |
| 2. Core UI      | 3-column layout, list views, forms      | ⬜     |
| 3. Settings     | Multi-tab settings window               | ⬜     |
| 4. AI Provider  | Protocol and service placeholder        | ⬜     |
| 5. MCP Server   | Server structure placeholder            | ⬜     |
| 6. Subscription | Manager with trial logic                | ⬜     |
| 7. Polish       | Liquid Glass, testing                   | ⬜     |
| 8. Multilingual | Localization, language settings         | ⬜     |
| 9. Review Mode  | Edit permissions, review schedule       | ⬜     |
| 10. Archiving   | Archive instead of delete, archive tab  | ⬜     |

**Estimated Total Time:** 6-8 hours for core implementation

**Next Steps After This Plan:**

1. Full AI provider implementations (OpenAI, Anthropic, Gemini, etc.)
2. Full MCP server with Swift NIO
3. StoreKit 2 integration for real IAP
4. Markdown editor with live preview
5. UI polish and animations
6. Review mode notifications
7. Additional language translations
