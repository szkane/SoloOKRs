// EditObjectiveView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-06.

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
                
                Section("Details") {
                    TextField("Title", text: $objective.title)
                    TextField("Description", text: $objective.objectiveDescription, axis: .vertical)
                        .lineLimit(2...4)
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
        .frame(minWidth: 400, minHeight: 400)
    }
}
