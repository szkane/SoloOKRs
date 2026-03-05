// SettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AIProviderSettingsView()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }

            MCPSettingsView()
                .tabItem {
                    Label("MCP", systemImage: "network")
                }

            SyncSettingsView()
                .tabItem {
                    Label("Sync", systemImage: "icloud")
                }

            SubscriptionSettingsView()
                .tabItem {
                    Label("Subscription", systemImage: "creditcard")
                }

            ReviewSettingsView()
                .tabItem {
                    Label("Review", systemImage: "calendar.badge.clock")
                }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 450, idealHeight: 550)
    }
}

#Preview {
    SettingsView()
}
