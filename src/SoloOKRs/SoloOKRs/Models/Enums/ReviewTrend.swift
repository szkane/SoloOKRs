// ReviewTrend.swift
// SoloOKRs
//
// Trend direction for KR progress tracking.

import Foundation

enum ReviewTrend: String, Codable, CaseIterable {
    case up = "Up"
    case down = "Down"
    case flat = "Flat"
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
    
    var color: String {
        switch self {
        case .up: return "green"
        case .down: return "red"
        case .flat: return "orange"
        }
    }
}
