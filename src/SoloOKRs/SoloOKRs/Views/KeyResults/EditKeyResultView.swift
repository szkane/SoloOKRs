// EditKeyResultView.swift
// SoloOKRs
//
// Simplified after KR type migration (2026-02-06).

import SwiftUI
import SwiftData

struct EditKeyResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var keyResult: KeyResult
    
    var body: some View {
        NavigationStack {
            Form {
                if !keyResult.isEditable {
                    Section {
                        Label("Read Only", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(LocalizedStringKey("Details")) {
                    TextField(LocalizedStringKey("Title"), text: $keyResult.title)
                }
                .disabled(!keyResult.isEditable)
                

                
                Section(LocalizedStringKey("Progress")) {
                    let completedCount = keyResult.tasks.filter { $0.isCompleted }.count
                    let totalCount = keyResult.tasks.count
                    
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("\(completedCount) / \(totalCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            
                            Text(LocalizedStringKey("tasks completed"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    
                    ProgressView(value: keyResult.progress)
                        .tint(keyResult.progress >= 1.0 ? .green : .blue)
                        .scaleEffect(y: 2)
                        .clipShape(.rect(cornerRadius: 4))
                }
                // Progress is derived, so no manual editing here anyway except maybe adding tasks (which is separate)
            }
            .formStyle(.grouped)
            .navigationTitle(LocalizedStringKey("Edit Key Result"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Done")) {
                        keyResult.updatedAt = Date()
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}
