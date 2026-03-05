// TaskListView.swift
// SoloOKRs
//
// Updated on 2026-02-13: Simplified — no task types, no subtasks.

import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @AppStorage("addingTaskKeyResultID") private var addingKeyResultID: String = ""
    let keyResult: KeyResult
    
    var body: some View {
        List {
            ForEach(keyResult.tasks) { task in
                TaskRowView(task: task)
            }
        }
        .navigationTitle(keyResult.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    addingKeyResultID = keyResult.id.uuidString
                    openWindow(id: "addTask")
                } label: {
                    Image(systemName: "checkmark.circle.badge.plus")
                        .help("Add Task")
                }
                .disabled(!ReviewModeManager.shared.canEditTask(for: keyResult))
            }
        }
    }
}

struct TaskRowView: View {
    @Bindable var task: OKRTask
    @Environment(\.openWindow) private var openWindow
    @AppStorage("editingTaskID") private var editingTaskID: String = ""
    @State private var isExpanded = false
    
    private var canEdit: Bool {
        task.isEditable
    }
    
    private var notesPreview: AttributedString {
        (try? AttributedString(markdown: task.taskDescription)) 
            ?? AttributedString(task.taskDescription)
    }
    
    private var needsExpansion: Bool {
        task.taskDescription.split(separator: "\n").count > 10 
            || task.taskDescription.count > 500
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completion checkbox
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(task.isCompleted ? .green : .secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                // Due date
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Markdown notes preview (expandable)
                if !task.taskDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notesPreview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(isExpanded ? nil : 10)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if needsExpansion {
                            Button(isExpanded ? "Show less" : "Read more...") {
                                withAnimation { isExpanded.toggle() }
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Priority Badge
            Text(task.priority.displayName)
                .font(.caption)
                .foregroundStyle(task.priority.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(task.priority.color.opacity(0.15), in: Capsule())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            editingTaskID = task.id.uuidString
            openWindow(id: "editTask")
        }
        .contextMenu {
            Button {
                editingTaskID = task.id.uuidString
                openWindow(id: "editTask")
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            if canEdit {
                Divider()
                Button(role: .destructive) {
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    let kr = KeyResult(title: "Preview KR")
    return TaskListView(keyResult: kr)
        .modelContainer(for: [KeyResult.self], inMemory: true)
}
