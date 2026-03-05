// ReviewType.swift
// SoloOKRs
//
// Review frequency types matching OKR best practices.

import Foundation
import SwiftUI

enum ReviewType: String, Codable, CaseIterable {
    case weekly = "weekly"
    case midCycle = "midCycle"
    case endCycle = "endCycle"
    
    var displayName: LocalizedStringKey {
        switch self {
        case .weekly: return "Weekly Check-in"
        case .midCycle: return "Mid-cycle Review"
        case .endCycle: return "End-cycle Review"
        }
    }
    
    var icon: String {
        switch self {
        case .weekly: return "calendar"
        case .midCycle: return "calendar.badge.clock"
        case .endCycle: return "calendar.badge.checkmark"
        }
    }
}
