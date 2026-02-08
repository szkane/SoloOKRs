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
                
                Section("Details") {
                    TextField("Title", text: $keyResult.title)
                }
                .disabled(!keyResult.isEditable)
                

                
                Section("Progress") {
                    let completedCount = keyResult.tasks.filter { $0.isCompleted }.count
                    let totalCount = keyResult.tasks.count
                    
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("\(completedCount) / \(totalCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            
                            Text("tasks completed")
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
                
                Section("Self Score (Review Mode)") {
                    HStack {
                        Text("Score")
                        Spacer()
                        Text(keyResult.selfScore != nil ? "\(keyResult.selfScore!)" : "Not Set")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(keyResult.selfScore ?? 50) },
                            set: { keyResult.selfScore = Int($0) }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .tint(.orange)
                    .disabled(!ReviewModeManager.shared.isInReviewMode) // Only editable in Review Mode specifically?
                    // Actually, if keyResult.isEditable is true, we are either in Draft (ok) or Active+ReviewMode (ok)
                    // But Self Score implies it's for Review.
                    // Let's stick to keyResult.isEditable for consistency, OR specific ReviewMode check?
                    // "Self Score (Review Mode)" suggests it's a review features.
                    // If in Draft, maybe we shouldn't set score?
                    // But Draft is editable.
                }
                .disabled(!keyResult.isEditable)
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Key Result")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        keyResult.updatedAt = Date()
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}
