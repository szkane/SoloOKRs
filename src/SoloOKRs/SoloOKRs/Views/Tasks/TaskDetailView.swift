// TaskDetailView.swift
// SoloOKRs
//
// Updated on 2026-02-13: Simplified — no task types, no subtasks.

import SwiftUI
import MarkdownUI

struct TaskDetailView: View {
    @Bindable var task: OKRTask
    let canEdit: Bool
    

    
    var body: some View {
        Form {
            Section("Title") {
                if canEdit {
                    TextField("Title", text: $task.title)
                        .onChange(of: task.title) { _, _ in
                            task.updatedAt = Date()
                        }
                } else {
                    Text(task.title)
                }
            }
            
            Section("Priority") {
                if canEdit {
                    Picker("Priority", selection: $task.priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Label(priority.displayName, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: task.priority) { _, _ in
                        task.updatedAt = Date()
                    }
                } else {
                    Label(task.priority.displayName, systemImage: task.priority.icon)
                        .foregroundStyle(task.priority.color)
                }
            }
            
            Section("Due Date") {
                if canEdit {
                    if task.dueDate != nil {
                        DatePicker("Due Date", selection: Binding(
                            get: { task.dueDate ?? Date() },
                            set: { task.dueDate = $0; task.updatedAt = Date() }
                        ), displayedComponents: .date)
                        
                        Button("Remove Due Date", role: .destructive) {
                            task.dueDate = nil
                            task.updatedAt = Date()
                        }
                    } else {
                        Button("Add Due Date") {
                            task.dueDate = Date()
                            task.updatedAt = Date()
                        }
                    }
                } else {
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .foregroundStyle(task.isOverdue ? .red : .primary)
                    } else {
                        Text("No due date")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Description") {
                if canEdit {
                    MarkdownEditorView(
                        text: $task.taskDescription,
                        placeholder: "Add a description..."
                    )
                    .frame(minHeight: 150)
                    .onChange(of: task.taskDescription) { _, _ in
                        task.updatedAt = Date()
                    }
                } else {
                    if task.taskDescription.isEmpty {
                        Text("No description")
                            .foregroundStyle(.secondary)
                    } else {
                        Markdown(task.taskDescription)
                            .textSelection(.enabled)
                            .markdownTheme(.gitHub)
                            .markdownCodeSyntaxHighlighter(.splash)
                    }
                }
            }
            
            Section("Status") {
                if canEdit {
                    Toggle("Completed", isOn: $task.isCompleted)
                        .onChange(of: task.isCompleted) { _, _ in
                            task.updatedAt = Date()
                        }
                } else {
                    Label(
                        task.isCompleted ? "Completed" : "In Progress",
                        systemImage: task.isCompleted ? "checkmark.circle.fill" : "circle"
                    )
                    .foregroundStyle(task.isCompleted ? .green : .primary)
                }
            }
            
            Section("Info") {
                LabeledContent("Created", value: task.createdAt, format: .dateTime)
                LabeledContent("Updated", value: task.updatedAt, format: .dateTime)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    TaskDetailView(task: OKRTask(title: "Sample Task"), canEdit: true)
}
