// KRReviewStatus.swift
// SoloOKRs
//
// Status assessment for a KR during a review.

import Foundation
import SwiftUI

enum KRReviewStatus: String, Codable, CaseIterable {
    case onTrack = "On Track"
    case atRisk = "At Risk"
    case offTrack = "Off Track"
    case blocked = "Blocked"
    
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
