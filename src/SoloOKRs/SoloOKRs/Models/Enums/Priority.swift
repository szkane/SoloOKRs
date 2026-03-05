// Priority.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import Foundation
import SwiftUI

enum Priority: Int, Codable, CaseIterable, Comparable {
    case low = 4
    case medium = 3
    case high = 2
    case urgent = 1
    
    var displayName: LocalizedStringResource {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle"
        }
    }
    
    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
