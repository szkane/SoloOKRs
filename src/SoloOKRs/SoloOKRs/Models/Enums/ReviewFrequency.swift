// ReviewFrequency.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import Foundation

enum ReviewFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
}
