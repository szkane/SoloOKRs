// GeneralSettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @AppStorage("defaultView") private var defaultView = "objectives"
    @AppStorage("preferredLanguage") private var preferredLanguage = ""

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
            }

            Section("Default View") {
                Picker("Focus on Launch", selection: $defaultView) {
                    Text("Objectives").tag("objectives")
                    Text("Key Results").tag("keyresults")
                    Text("Tasks").tag("tasks")
                }
                .pickerStyle(.radioGroup)
            }

            Section("Language") {
                Picker("App Language", selection: $preferredLanguage) {
                    Text("System Default").tag("")
                    Divider()
                    Text("English").tag("en")
                    Text("简体中文").tag("zh-Hans")
                    Text("Deutsch").tag("de")
                    Text("Français").tag("fr")
                    Text("Español").tag("es")
                    Text("Português").tag("pt-BR")
                }
            }

            Section("Appearance") {
                Text("Theme follows system settings")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

#Preview {
    GeneralSettingsView()
}
