// ReviewModeManager.swift
// SoloOKRs
//
// Review mode and notification scheduling

import Foundation
import SwiftUI
import UserNotifications

@Observable
@MainActor
class ReviewModeManager {
    static let shared = ReviewModeManager()

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
    var dayOfWeek: Int = 1 {  // Monday = 1
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
        // Load saved state
        isInReviewMode = UserDefaults.standard.bool(forKey: "isInReviewMode")
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
        
        // Cancel existing
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        
        guard reviewEnabled else { return }
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "OKR Review Time"
        content.body = "It's time for your weekly OKR check-in. Review your progress and update key results."
        content.sound = .default
        
        // Create trigger based on frequency
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        switch frequency {
        case .weekly:
            dateComponents.weekday = dayOfWeek + 1  // DateComponents weekday is 1=Sunday
        case .biweekly:
            // Every 2 weeks - approximate with weekly trigger
            dateComponents.weekday = dayOfWeek + 1
        case .monthly:
            dateComponents.day = 1  // First of each month
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
    
    // MARK: - Review Mode

    func enterReviewMode() {
        isInReviewMode = true
        UserDefaults.standard.set(true, forKey: "isInReviewMode")
    }

    func exitReviewMode() {
        isInReviewMode = false
        UserDefaults.standard.set(false, forKey: "isInReviewMode")
    }

    /// Check if an Objective/KeyResult can be edited
    func canEditOKR(status: OKRStatus) -> Bool {
        switch status {
        case .draft:
            return true
        case .active:
            return isInReviewMode  // Only editable in review mode
        case .review:
            return true
        case .achieved, .archived:
            return false
        }
    }

    /// Check if a Task can be edited
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
}
