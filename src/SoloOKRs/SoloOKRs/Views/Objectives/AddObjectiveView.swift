// AddObjectiveView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import SwiftUI
import SwiftData

struct AddObjectiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Objective.order) private var objectives: [Objective]
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var status: OKRStatus = .draft
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Timeline") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                // Status selection removed - defaults to .draft
                // Section("Status") { ... }
            }
            .formStyle(.grouped)
            .navigationTitle("New Objective")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addObjective()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }
    
    private func addObjective() {
        let newObjective = Objective(
            title: title,
            objectiveDescription: description,
            startDate: startDate,
            endDate: endDate,
            status: status,
            order: objectives.count
        )
        modelContext.insert(newObjective)
        dismiss()
    }
}

#Preview {
    AddObjectiveView()
        .modelContainer(for: [Objective.self], inMemory: true)
}
