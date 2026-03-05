// KRReviewStatus.swift
// SoloOKRs
//
// Status assessment for a KR during a review.

import Foundation
import SwiftUI

enum KRReviewStatus: String, Codable, CaseIterable {
    case onTrack = "onTrack"
    case atRisk = "atRisk"
    case offTrack = "offTrack"
    case blocked = "blocked"
    
    var displayName: LocalizedStringKey {
        switch self {
        case .onTrack: return "On Track"
        case .atRisk: return "At Risk"
        case .offTrack: return "Off Track"
        case .blocked: return "Blocked"
        }
    }
    
    var icon: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .atRisk: return "exclamationmark.triangle.fill"
        case .offTrack: return "xmark.circle.fill"
        case .blocked: return "hand.raised.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .onTrack: return .green
        case .atRisk: return .orange
        case .offTrack: return .red
        case .blocked: return .purple
        }
    }
}
