// AddTaskWindowView.swift
// SoloOKRs
//
// Wrapper view for Add Task window - uses AppStorage to receive keyResult ID

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
                ContentUnavailableView("No Key Result Selected", systemImage: "doc.questionmark")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

struct AddTaskContent: View {
    let keyResult: KeyResult
    var onComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var description = ""
    @State private var type: TaskType = .simple
    @State private var priority: Priority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var targetValue: Double = 100
    @State private var milestones: [String] = []
    @State private var milestoneText = ""
    
    var body: some View {
        HSplitView {
            // LEFT: Basic Info Form
            Form {
                Section("Title") {
                    TextField("", text: $title)
                        .font(.title3)
                }
                
                Section("Type") {
                    Picker("Type", selection: $type.animation()) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if type == .numeric {
                    Section("Target Value") {
                        HStack {
                            Text("Target:")
                            TextField("", value: $targetValue, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }
                } else if type == .milestone {
                    Section("Milestones") {
                        ForEach(milestones.indices, id: \.self) { index in
                            HStack {
                                Text("\(index + 1).")
                                Text(milestones[index])
                                Spacer()
                                Button(role: .destructive) {
                                    milestones.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        HStack {
                            TextField("Add milestone...", text: $milestoneText)
                            Button("Add") {
                                if !milestoneText.isEmpty {
                                    milestones.append(milestoneText)
                                    milestoneText = ""
                                }
                            }
                            .disabled(milestoneText.isEmpty)
                        }
                    }
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
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
            
            // RIGHT: Markdown Notes Editor
            VStack(alignment: .leading, spacing: 0) {
                Text("Notes")
                    .font(.headline)
                    .padding()
                
                MarkdownEditorView(
                    text: $description,
                    placeholder: "Add notes (Markdown supported)..."
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(minWidth: 500, idealWidth: 700)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onComplete()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTask()
                    onComplete()
                }
                .disabled(title.isEmpty)
            }
        }
    }
    
    private func saveTask() {
        let task = OKRTask(title: title, type: type)
        task.taskDescription = description
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.keyResult = keyResult
        
        switch type {
        case .simple:
            break
        case .percentage:
            task.currentValue = 0
        case .numeric:
            task.targetValue = targetValue
            task.currentValue = 0
        case .milestone:
            task.milestones = milestones
            task.completedMilestones = milestones.map { _ in false }
        }
        
        modelContext.insert(task)
        keyResult.tasks.append(task)
    }
}
