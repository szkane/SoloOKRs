// OKRStatus.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import Foundation

enum OKRStatus: String, Codable, CaseIterable {
    case draft      // Not yet started
    case active     // Currently being worked on
    case review     // Pending review (important for regular OKR check-ins)
    case achieved   // Successfully completed
    case archived   // No longer relevant, kept for history
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .review: return "Review"
        case .achieved: return "Achieved"
        case .archived: return "Archived"
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.badge.clock"
        case .active: return "play.circle"
        case .review: return "eye.circle"
        case .achieved: return "checkmark.seal"
        case .archived: return "archivebox"
        }
    }
}
