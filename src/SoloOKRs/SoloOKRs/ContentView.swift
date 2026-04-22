// ContentView.swift
// SoloOKRs
//
// Created by Kane on 2/4/26.

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Objective.order) private var objectives: [Objective]
    
    @State private var selectedObjective: Objective?
    @State private var selectedKeyResult: KeyResult?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @AppStorage("selectedSettingsTab") private var selectedTab: String = "general"
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ObjectiveListView(
                selectedObjective: $selectedObjective,
                selectedKeyResult: $selectedKeyResult
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } content: {
            if let objective = selectedObjective {
                KeyResultListView(
                    objective: objective,
                    selectedKeyResult: $selectedKeyResult
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 280, max: 400)
            } else {
                ContentUnavailableView(
                    "Select an Objective",
                    systemImage: "target",
                    description: Text("Choose an objective from the sidebar to see its key results")
                )
            }
        } detail: {
            if let keyResult = selectedKeyResult {
                TaskListView(keyResult: keyResult)
            } else {
                ContentUnavailableView(
                    "Select a Key Result",
                    systemImage: "list.bullet",
                    description: Text("Choose a key result to see its tasks")
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: selectedObjective) { _, newValue in
            // Clear key result selection when objective changes
            if newValue != selectedObjective {
                selectedKeyResult = nil
            }
        }
        .onChange(of: objectives) { _, newValue in
            // If objectives are cleared (e.g. from Sync settings), reset selections
            if newValue.isEmpty {
                selectedObjective = nil
                selectedKeyResult = nil
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Objective.self, KeyResult.self, OKRTask.self], inMemory: true)
}
