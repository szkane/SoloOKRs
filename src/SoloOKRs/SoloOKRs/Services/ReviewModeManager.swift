// ReviewModeManager.swift
// SoloOKRs
//
// Simplified 2026-03-05: Removed global review mode toggle.
// Keeps notification/reminder functionality. Edit permissions now status-based only.

import Foundation
import SwiftUI
import UserNotifications

@Observable
@MainActor
class ReviewModeManager {
    static let shared = ReviewModeManager()

    // Review Mode is retained for backward compatibility but simplified
    private(set) var isInReviewMode = false
    
    var reviewEnabled = true {
        didSet {
            UserDefaults.standard.set(reviewEnabled, forKey: "reviewEnabled")
            Task { await scheduleOrCancelReminder() }
        }
    }
    var frequency: ReviewFrequency = .weekly {
        didSet {
            UserDefaults.standard.set(frequency.rawValue, forKey: "reviewFrequency")
            Task { await scheduleOrCancelReminder() }
        }
    }
    var dayOfWeek: Int = 1 {
        didSet {
            UserDefaults.standard.set(dayOfWeek, forKey: "reviewDayOfWeek")
            Task { await scheduleOrCancelReminder() }
        }
    }
    var reminderHour: Int = 9 {
        didSet {
            UserDefaults.standard.set(reminderHour, forKey: "reviewHour")
            Task { await scheduleOrCancelReminder() }
        }
    }
    var reminderMinute: Int = 0 {
        didSet {
            UserDefaults.standard.set(reminderMinute, forKey: "reviewMinute")
            Task { await scheduleOrCancelReminder() }
        }
    }
    
    private let notificationID = "com.szkane.SoloOKRs.reviewReminder"

    private init() {
        reviewEnabled = UserDefaults.standard.object(forKey: "reviewEnabled") as? Bool ?? true
        if let freqRaw = UserDefaults.standard.string(forKey: "reviewFrequency"),
           let freq = ReviewFrequency(rawValue: freqRaw) {
            frequency = freq
        }
        dayOfWeek = UserDefaults.standard.object(forKey: "reviewDayOfWeek") as? Int ?? 1
        reminderHour = UserDefaults.standard.object(forKey: "reviewHour") as? Int ?? 9
        reminderMinute = UserDefaults.standard.object(forKey: "reviewMinute") as? Int ?? 0
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await scheduleOrCancelReminder()
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    private func scheduleOrCancelReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        
        guard reviewEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "OKR Review Time"
        content.body = "It's time for your OKR check-in. Review your progress and update key results."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        switch frequency {
        case .weekly:
            dateComponents.weekday = dayOfWeek + 1
        case .biweekly:
            dateComponents.weekday = dayOfWeek + 1
        case .monthly:
            dateComponents.day = 1
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("Scheduled review reminder: \(dateComponents)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Edit Permissions (simplified: status-based only)

    func canEditOKR(status: OKRStatus) -> Bool {
        switch status {
        case .draft, .active, .review:
            return true
        case .achieved, .archived:
            return false
        }
    }

    func canEditTask(_ task: OKRTask) -> Bool {
        guard let parentStatus = task.keyResult?.objective?.status else {
            return true
        }
        switch parentStatus {
        case .draft, .active, .review:
            return true
        case .achieved, .archived:
            return false
        }
    }
    
    func canEditTask(for keyResult: KeyResult) -> Bool {
        guard let status = keyResult.objective?.status else { return true }
        switch status {
        case .draft, .active, .review:
            return true
        case .achieved, .archived:
            return false
        }
    }
}
