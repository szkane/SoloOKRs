// SyncSettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import SwiftUI

struct SyncSettingsView: View {
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
        }
        .formStyle(.grouped)
        .navigationTitle("Sync")
    }
}

#Preview {
    SyncSettingsView()
}
