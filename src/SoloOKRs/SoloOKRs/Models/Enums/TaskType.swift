// TaskType.swift
// SoloOKRs
//
// Migrated from KeyResultType on 2026-02-06.
// Task types define how task progress is tracked.

import Foundation
import SwiftUI

enum TaskType: String, Codable, CaseIterable {
    case simple      // Simple checkbox (done or not done)
    case percentage  // 0-100% slider
    case numeric     // current/target values
    case milestone   // Multiple checkpoints
    
    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .percentage: return "Percentage"
        case .numeric: return "Numeric Target"
        case .milestone: return "Milestones"
        }
    }
    
    var icon: String {
        switch self {
        case .simple: return "checkmark.circle"
        case .percentage: return "percent"
        case .numeric: return "number"
        case .milestone: return "flag.checkered"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .simple: return .blue
        case .percentage: return .orange
        case .numeric: return .purple
        case .milestone: return .green
        }
    }
}
