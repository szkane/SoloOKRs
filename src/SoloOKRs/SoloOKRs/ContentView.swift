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
    @State private var showingClearConfirmation = false
    
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
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
            #endif
            
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 12) {
                    // AI Status
                    if AIService.shared.isConfigured {
                        Label("AI Ready", systemImage: "brain")
                            .foregroundStyle(.green)
                    }

                    // MCP Status
                    if MCPServer.shared.isRunning {
                        Label("MCP", systemImage: "network")
                            .foregroundStyle(.green)
                    }

                    // Sync Status
                    Label("Synced", systemImage: "icloud.fill")
                        .foregroundStyle(.green)
                }
                .font(.caption)
            }
        }
        .confirmationDialog("Clear All Data?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Delete All Objectives, Key Results & Tasks", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your OKR data. This action cannot be undone.")
        }
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: selectedObjective) { _, newValue in
            // Clear key result selection when objective changes
            if newValue != selectedObjective {
                selectedKeyResult = nil
            }
        }
    }
    
    private func clearAllData() {
        // 1. Clear selection state immediately to reset UI
        selectedKeyResult = nil
        selectedObjective = nil
        
        // 2. Perform batch deletion after a brief delay
        // Using batch delete avoids accessing individual object instances that might be in a state of flux
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                try modelContext.delete(model: Objective.self)
                try modelContext.save()
            } catch {
                print("Failed to clear data: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Objective.self, KeyResult.self, OKRTask.self], inMemory: true)
}
