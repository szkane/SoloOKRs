// SettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-04.

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedSettingsTab") private var selectedTab: String = "general"

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")

            AIProviderSettingsView()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
                .tag("ai")

            PromptSettingsView()
                .tabItem {
                    Label("Prompts", systemImage: "text.bubble")
                }
                .tag("prompts")

            MCPSettingsView()
                .tabItem {
                    Label("MCP", systemImage: "network")
                }
                .tag("mcp")

            SyncSettingsView()
                .tabItem {
                    Label("Sync", systemImage: "icloud")
                }
                .tag("sync")

            SubscriptionSettingsView()
                .tabItem {
                    Label("Subscription", systemImage: "creditcard")
                }
                .tag("subscription")
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 450, idealHeight: 550)
    }
}

#Preview {
    SettingsView()
}
