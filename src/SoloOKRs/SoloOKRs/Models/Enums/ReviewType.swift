// ReviewType.swift
// SoloOKRs
//
// Review frequency types matching OKR best practices.

import Foundation

enum ReviewType: String, Codable, CaseIterable {
    case weekly = "Weekly Check-in"
    case midCycle = "Mid-cycle Review"
    case endCycle = "End-cycle Review"
    
    var icon: String {
        switch self {
        case .weekly: return "calendar"
        case .midCycle: return "calendar.badge.clock"
        case .endCycle: return "calendar.badge.checkmark"
        }
    }
}
