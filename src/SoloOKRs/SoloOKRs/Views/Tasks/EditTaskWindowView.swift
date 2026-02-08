// EditTaskWindowView.swift
// SoloOKRs
//
// Wrapper view for Edit Task window - uses AppStorage to receive task ID

import SwiftUI
import SwiftData

struct EditTaskWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("editingTaskID") private var editingTaskID: String = ""
    
    @Query private var tasks: [OKRTask]
    
    private var task: OKRTask? {
        guard !editingTaskID.isEmpty,
              let uuid = UUID(uuidString: editingTaskID) else { return nil }
        return tasks.first { $0.id == uuid }
    }
    
    var body: some View {
        Group {
            if let task = task {
                EditTaskContent(task: task, onDone: {
                    editingTaskID = ""
                    dismiss()
                })
            } else {
                ContentUnavailableView("No Task Selected", systemImage: "doc.questionmark")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

struct EditTaskContent: View {
    @Bindable var task: OKRTask
    var onDone: () -> Void
    
    var body: some View {
        HSplitView {
            // LEFT: Basic Info Form
            Form {
                if !task.isEditable {
                    Section {
                        Label("Read Only", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Title") {
                    TextField("", text: $task.title)
                        .font(.title3)
                }
                .disabled(!task.isEditable)
                
                Section("Type") {
                    Label(task.type.displayName, systemImage: task.type.icon)
                        .foregroundStyle(task.type.iconColor)
                }
                
                Section("Progress") {
                    TaskProgressEditor(task: task)
                }
                .disabled(!task.isEditable)
                
                Section("Priority & Status") {
                    Picker("Priority", selection: $task.priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Label(priority.displayName, systemImage: priority.icon)
                                .foregroundColor(priority.color)
                                .tag(priority)
                        }
                    }
                    
                    if task.type == .simple {
                        Toggle("Completed", isOn: $task.isCompleted)
                    }
                }
                .disabled(!task.isEditable)
                
                Section("Due Date") {
                    DatePicker("Due Date", selection: Binding(
                        get: { task.dueDate ?? Date() },
                        set: { task.dueDate = $0 }
                    ), displayedComponents: .date)
                    
                    Button("Clear Due Date") {
                        task.dueDate = nil
                    }
                    .disabled(task.dueDate == nil)
                }
                .disabled(!task.isEditable)
            }
            .formStyle(.grouped)
            .frame(minWidth: 270, idealWidth: 300, maxWidth: 350)
            
            // RIGHT: Markdown Notes Editor
            VStack(alignment: .leading, spacing: 0) {
                Text("Notes")
                    .font(.headline)
                    .padding()
                
                if task.isEditable {
                    MarkdownEditorView(
                        text: $task.taskDescription,
                        placeholder: "Add notes (Markdown supported)..."
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        if task.taskDescription.isEmpty {
                            Text("No notes")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text((try? AttributedString(markdown: task.taskDescription)) 
                                 ?? AttributedString(task.taskDescription))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
            }
            .frame(minWidth: 500, idealWidth: 700)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onDone()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    task.updatedAt = Date()
                    onDone()
                }
            }
        }
    }
}
