// ReviewSettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import SwiftUI

struct ReviewSettingsView: View {
    @State private var reviewManager = ReviewModeManager.shared

    var body: some View {
        Form {
            Section("Review Schedule") {
                Toggle("Enable Review Reminders", isOn: $reviewManager.reviewEnabled)

                if reviewManager.reviewEnabled {
                    Picker("Frequency", selection: $reviewManager.frequency) {
                        ForEach(ReviewFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    Picker("Day", selection: $reviewManager.dayOfWeek) {
                        Text("Monday").tag(1)
                        Text("Tuesday").tag(2)
                        Text("Wednesday").tag(3)
                        Text("Thursday").tag(4)
                        Text("Friday").tag(5)
                        Text("Saturday").tag(6)
                        Text("Sunday").tag(7)
                    }

                    HStack {
                        Text("Time")
                        Spacer()
                        Text("\(reviewManager.reminderHour):\(String(format: "%02d", reviewManager.reminderMinute))")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Review Mode") {
                if reviewManager.isInReviewMode {
                    HStack {
                        Circle().fill(.orange).frame(width: 10, height: 10)
                        Text("Review Mode Active")
                    }
                    Button("Exit Review Mode") {
                        reviewManager.exitReviewMode()
                    }
                    .foregroundStyle(.orange)
                } else {
                    HStack {
                        Circle().fill(.gray).frame(width: 10, height: 10)
                        Text("Normal Mode")
                    }
                    Button("Enter Review Mode") {
                        reviewManager.enterReviewMode()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Review")
    }
}

#Preview {
    ReviewSettingsView()
}
