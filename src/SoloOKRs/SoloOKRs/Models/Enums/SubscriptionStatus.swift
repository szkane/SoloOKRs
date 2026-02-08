// SubscriptionStatus.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import Foundation

enum SubscriptionStatus: String, Codable {
    case trial       // Within trial limits
    case subscribed  // Purchased/subscribed
    case expired     // Subscription lapsed
}
