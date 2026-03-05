// ReviewTrend.swift
// SoloOKRs
//
// Trend direction for KR progress tracking.

import Foundation
import SwiftUI

enum ReviewTrend: String, Codable, CaseIterable {
    case up = "up"
    case down = "down"
    case flat = "flat"
    
    var displayName: LocalizedStringKey {
        switch self {
        case .up: return "Improving"
        case .down: return "Declining"
        case .flat: return "Steady"
        }
    }
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
    
    var swiftUIColor: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .flat: return .orange
        }
    }
}
