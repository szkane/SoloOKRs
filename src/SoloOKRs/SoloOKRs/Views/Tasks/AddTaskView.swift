// AddTaskView.swift
// SoloOKRs
//
// Updated on 2026-02-13: Simplified — no task types, no subtasks.

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let keyResult: KeyResult
    
    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: Priority = .medium
    
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // LEFT: Basic Info Form
                Form {
                    Section(LocalizedStringKey("Title")) {
                        TextField("", text: $title)
                            .font(.title3)
                    }
                    
                    Section(LocalizedStringKey("Due Date")) {
                        Toggle(LocalizedStringKey("Set Due Date"), isOn: $hasDueDate)
                        if hasDueDate {
                            DatePicker(LocalizedStringKey("Due Date"), selection: $dueDate, displayedComponents: .date)
                        }
                    }
                    
                    Section(LocalizedStringKey("Priority")) {
                        Picker(LocalizedStringKey("Priority"), selection: $priority) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Label(priority.displayName, systemImage: priority.icon)
                                    .tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .formStyle(.grouped)
                .contentMargins(.top, 50)
                .frame(minWidth: 280, idealWidth: 320)
                
                // RIGHT: Markdown Notes Editor
                VStack(alignment: .leading, spacing: 0) {
                    Text(LocalizedStringKey("Notes"))
                        .font(.headline)
                        .padding()
                    
                    MarkdownEditorView(
                        text: $description,
                        placeholder: String(localized: "Add notes (Markdown supported)...")
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top, 50)
                .frame(minWidth: 300)
            }
            .navigationTitle(LocalizedStringKey("New Task"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) { dismiss() }
                }
                
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Add")) { addTask() }
                        .disabled(title.isEmpty)
                }
            }

        }
        .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, minHeight: 600, idealHeight: 700, maxHeight: .infinity)
    }
    

    
    private func addTask() {
        let task = OKRTask(
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
    AddTaskView(keyResult: KeyResult(title: "Test KR"))
        .modelContainer(for: [KeyResult.self], inMemory: true)
}
