// EditObjectiveView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-06.
// Updated 2026-03-05: Markdown editor for description.

import SwiftUI
import SwiftData

struct EditObjectiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var objective: Objective
    
    private var canEdit: Bool {
        ReviewModeManager.shared.canEditOKR(status: objective.status)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !canEdit {
                    Section {
                        Label("Read Only", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Title") {
                    TextField("Title", text: $objective.title)
                }
                .disabled(!canEdit)
                
                Section("Description") {
                    MarkdownEditorView(text: $objective.objectiveDescription, placeholder: "Describe the objective...")
                        .frame(minHeight: 150)
                }
                .disabled(!canEdit)
                
                Section("Timeline") {
                    DatePicker("Start Date", selection: $objective.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $objective.endDate, displayedComponents: .date)
                }
                .disabled(!canEdit)
                
                Section("Status") {
                    Text(objective.status.displayName)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(canEdit ? "Edit Objective" : "View Objective")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}
