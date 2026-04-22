// AddTaskWindowView.swift
// SoloOKRs
//
// Updated on 2026-02-13: Simplified — no task types, no subtasks.

import SwiftUI
import SwiftData

struct AddTaskWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("addingTaskKeyResultID") private var keyResultID: String = ""
    
    @Query private var keyResults: [KeyResult]
    
    private var keyResult: KeyResult? {
        guard !keyResultID.isEmpty,
              let uuid = UUID(uuidString: keyResultID) else { return nil }
        return keyResults.first { $0.id == uuid }
    }
    
    var body: some View {
        Group {
            if let keyResult = keyResult {
                AddTaskContent(keyResult: keyResult, onComplete: {
                    keyResultID = ""
                    dismiss()
                })
            } else {
                ContentUnavailableView(LocalizedStringKey("No Key Result Selected"), systemImage: "doc.questionmark")
            }
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #else
        .frame(minWidth: 320, minHeight: 500)
        #endif
    }
}

struct AddTaskContent: View {
    let keyResult: KeyResult
    var onComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Priority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                #if os(macOS)
                HSplitView {
                    formPane(isCompact: false)
                    notesPane(isCompact: false)
                }
                #else
                if geometry.size.width >= 820 {
                    HStack(spacing: 0) {
                        formPane(isCompact: false)
                        Divider()
                        notesPane(isCompact: false)
                    }
                } else {
                    VStack(spacing: 0) {
                        formPane(isCompact: true)
                        Divider()
                        notesPane(isCompact: true)
                    }
                }
                #endif
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey("Cancel")) {
                    onComplete()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey("Save")) {
                    saveTask()
                    onComplete()
                }
                .disabled(title.isEmpty)
            }
        }
    }

    private func formPane(isCompact: Bool) -> some View {
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
                    Picker("", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Label(priority.displayName, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: isCompact ? .infinity : 420)
    }

    private func notesPane(isCompact: Bool) -> some View {
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
        .frame(maxWidth: .infinity, minHeight: isCompact ? 260 : nil)
    }
    
    private func saveTask() {
        let task = OKRTask(title: title)
        task.taskDescription = description
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.keyResult = keyResult
        
        modelContext.insert(task)
        keyResult.tasks.append(task)
    }
}
