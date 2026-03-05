// ReviewSettingsView.swift
// SoloOKRs
//
// Deprecated: Review mode is now per-Objective. This file kept for Xcode project compatibility.

import SwiftUI

struct ReviewSettingsView: View {
    private let reviewManager = ReviewModeManager.shared

    var body: some View {
        Form {
            Section("Review Reminders") {
                Text("Review reminders are managed via notifications.")
                    .foregroundStyle(.secondary)
                Text("Use the context menu on an Objective to create a new review.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Review")
    }
}

#Preview {
    ReviewSettingsView()
}
