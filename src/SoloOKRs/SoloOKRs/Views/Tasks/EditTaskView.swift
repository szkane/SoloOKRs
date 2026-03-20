// EditTaskView.swift
// SoloOKRs
//
// Updated on 2026-02-13: Simplified — no task types, no subtasks.

import SwiftUI
import SwiftData
import MarkdownUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: OKRTask
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // LEFT: Basic Info Form
                Form {
                    if !task.isEditable {
                        Section {
                            Label(LocalizedStringKey("Read Only"), systemImage: "lock.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section(LocalizedStringKey("Title")) {
                        TextField("", text: $task.title)
                            .font(.title3)
                    }
                    .disabled(!task.isEditable)
                    
                    Section(LocalizedStringKey("Status")) {
                        Toggle(LocalizedStringKey("Completed"), isOn: $task.isCompleted)
                    }
                    .disabled(!task.isEditable)
                    
                    Section(LocalizedStringKey("Priority")) {
                        Picker(LocalizedStringKey("Priority"), selection: $task.priority) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Label(priority.displayName, systemImage: priority.icon)
                                    .foregroundColor(priority.color)
                                    .tag(priority)
                            }
                        }
                    }
                    .disabled(!task.isEditable)
                    
                    Section(LocalizedStringKey("Due Date")) {
                        DatePicker(LocalizedStringKey("Due Date"), selection: Binding(
                            get: { task.dueDate ?? Date() },
                            set: { task.dueDate = $0 }
                        ), displayedComponents: .date)
                        
                        Button(LocalizedStringKey("Clear Due Date")) {
                            task.dueDate = nil
                        }
                        .disabled(task.dueDate == nil)
                    }
                    .disabled(!task.isEditable)
                }
                .formStyle(.grouped)
                .contentMargins(.top, 50)
                .frame(minWidth: 280, idealWidth: 350)
                
                // RIGHT: Markdown Notes Editor
                VStack(alignment: .leading, spacing: 0) {
                    Text(LocalizedStringKey("Notes"))
                        .font(.headline)
                        .padding()
                    
                    if task.isEditable {
                        MarkdownEditorView(
                            text: $task.taskDescription,
                            placeholder: String(localized: "Add notes (Markdown supported)...")
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            if task.taskDescription.isEmpty {
                                Text(LocalizedStringKey("No notes"))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Markdown(task.taskDescription)
                                    .textSelection(.enabled)
                                    .markdownTheme(.gitHub)
                                    .markdownCodeSyntaxHighlighter(.splash)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                }
                .padding(.top, 50)
                .frame(minWidth: 300)
            }
            .navigationTitle(LocalizedStringKey("Edit Task"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Done")) {
                        task.updatedAt = Date()
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, minHeight: 600, idealHeight: 700, maxHeight: .infinity)
    }
}
