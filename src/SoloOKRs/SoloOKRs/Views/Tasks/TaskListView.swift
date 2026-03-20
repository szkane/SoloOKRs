// TaskListView.swift
// SoloOKRs
//
// Updated on 2026-02-13: Simplified — no task types, no subtasks.

import SwiftUI
import SwiftData
import MarkdownUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @AppStorage("addingTaskKeyResultID") private var addingKeyResultID: String = ""
    @State private var selectedTaskID: UUID?
    let keyResult: KeyResult
    
    var body: some View {
        VSplitView {
            List(selection: $selectedTaskID) {
                ForEach(keyResult.tasks) { task in
                    TaskRowView(task: task, selectedTaskID: $selectedTaskID)
                        .tag(task.id)
                }
            }
            .frame(minHeight: 150)
            
            VStack {
                if let selectedID = selectedTaskID, let task = keyResult.tasks.first(where: { $0.id == selectedID }) {
                    if task.taskDescription.isEmpty {
                        Text("This task has no details.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            Markdown(task.taskDescription)
                                .textSelection(.enabled)
                                .markdownTheme(.gitHub)
                                .markdownCodeSyntaxHighlighter(.splash)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                } else {
                    Text("No task selected")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minHeight: 100)
        }
        .navigationTitle(keyResult.title)
        .toolbar {
            ToolbarItem(placement: .automatic) {
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
    @Binding var selectedTaskID: UUID?
    @Environment(\.openWindow) private var openWindow
    @AppStorage("editingTaskID") private var editingTaskID: String = ""
    
    private var canEdit: Bool {
        task.isEditable
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completion checkbox
            Button {
                if canEdit {
                    task.isCompleted.toggle()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .frame(width: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
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
        .onTapGesture(count: 2) {
            editingTaskID = task.id.uuidString
            openWindow(id: "editTask")
        }
        .simultaneousGesture(TapGesture().onEnded {
            selectedTaskID = task.id
        })
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
