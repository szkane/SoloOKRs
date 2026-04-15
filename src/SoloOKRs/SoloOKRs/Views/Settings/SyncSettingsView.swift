// SyncSettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import SwiftUI
import SwiftData

struct SyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearConfirmation = false
    @State private var showingError = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("iCloud Sync") {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                    Text("Synced")
                }

                Text("Changes sync automatically via iCloud")
                    .foregroundStyle(.secondary)
            }

            Section("Actions") {
                Button("Sync Now") {
                    // Manual sync trigger
                }
            }

            // Danger Zone
            Section("Danger Zone") {
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete All App Data")
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Sync")
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onChange(of: errorMessage) { _, newValue in
            showingError = newValue != nil
        }
        .confirmationDialog("Clear All Data?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Delete All Objectives, Key Results & Tasks", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your OKR data. This action cannot be undone.")
        }
    }

    private func clearAllData() {
        DispatchQueue.main.async {
            do {
                // Delete all top-level entities. 
                // SwiftData batch deletion (modelContext.delete(model: Type.self))
                // is efficient and should trigger cascades if rules are set correctly.
                try modelContext.delete(model: Objective.self)
                try modelContext.delete(model: OKRTask.self)
                try modelContext.delete(model: OKRReview.self)
                
                // Explicitly delete dependent models just in case of orphaning
                try modelContext.delete(model: KeyResult.self)
                try modelContext.delete(model: KRReviewEntry.self)
                
                try modelContext.save()
            } catch {
                errorMessage = "Failed to clear data: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    SyncSettingsView()
        .modelContainer(for: [Objective.self, KeyResult.self, OKRTask.self, OKRReview.self, KRReviewEntry.self], inMemory: true)
}
