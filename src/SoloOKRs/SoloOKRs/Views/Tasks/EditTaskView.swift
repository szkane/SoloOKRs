// EditTaskView.swift
// SoloOKRs
//
// Updated on 2026-02-06: Added type-specific editing after KR type migration.

import SwiftUI
import SwiftData

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
                        // Task type is read-only after creation (different types have different data structures)
                        Label(task.type.displayName, systemImage: task.type.icon)
                            .foregroundStyle(task.type.iconColor)
                    }
                        
                        // Type-Specific Progress Editor
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
                .contentMargins(.top, 50)
                .frame(minWidth: 280, idealWidth: 350)
                
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
                        // Read-only markdown display
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
                .padding(.top, 50)
                .frame(minWidth: 300)
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        task.updatedAt = Date()
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, minHeight: 600, idealHeight: 700, maxHeight: .infinity)
    }
}

// MARK: - Task Progress Editor (Type-Specific)

struct TaskProgressEditor: View {
    @Bindable var task: OKRTask
    @State private var newMilestoneText = ""
    
    var body: some View {
        switch task.type {
        case .simple:
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                Text(task.isCompleted ? "Completed" : "Not Completed")
                Spacer()
            }
            
        case .percentage:
            VStack(spacing: 12) {
                HStack {
                    Text("\(Int(task.currentValue ?? 0))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Spacer()
                }
                Slider(
                    value: Binding(
                        get: { task.currentValue ?? 0 },
                        set: { task.currentValue = $0 }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(.blue)
            }
            
        case .numeric:
            VStack(spacing: 12) {
                HStack {
                    Text("\(Int(task.currentValue ?? 0)) / \(Int(task.targetValue ?? 100))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    VStack {
                        Text("Current")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button { task.currentValue = max(0, (task.currentValue ?? 0) - 1) } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            
                            Button { task.currentValue = min((task.currentValue ?? 0) + 1, task.targetValue ?? 100) } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.title2)
                        .foregroundStyle(.blue)
                    }
                    
                    VStack {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button { task.targetValue = max(1, (task.targetValue ?? 100) - 1) } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.plain)
                            
                            Button { task.targetValue = (task.targetValue ?? 100) + 1 } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    }
                }
                
                ProgressView(value: task.progress)
                    .tint(task.progress >= 1.0 ? .green : .blue)
            }
            .onAppear {
                if task.targetValue == nil { task.targetValue = 100 }
            }
            
        case .milestone:
            VStack(alignment: .leading, spacing: 8) {
                // Summary
                let completed = task.completedMilestones.filter { $0 }.count
                Text("\(completed) of \(task.milestones.count) completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                // Milestone List
                ForEach(task.milestones.indices, id: \.self) { index in
                    HStack {
                        Button {
                            withAnimation { task.completedMilestones[index].toggle() }
                        } label: {
                            Image(systemName: task.completedMilestones[index] ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.completedMilestones[index] ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Text(task.milestones[index])
                            .strikethrough(task.completedMilestones[index])
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            withAnimation {
                                task.milestones.remove(at: index)
                                task.completedMilestones.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Add Milestone
                HStack {
                    TextField("New milestone...", text: $newMilestoneText)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        guard !newMilestoneText.isEmpty else { return }
                        withAnimation {
                            task.milestones.append(newMilestoneText)
                            task.completedMilestones.append(false)
                            newMilestoneText = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(newMilestoneText.isEmpty)
                }
            }
        }
    }
}
