// MCPSettingsView.swift
// SoloOKRs

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MCPSettingsView: View {
    @Bindable var mcpServer = MCPServer.shared
    @AppStorage("mcpServerPort") private var savedPort = 5100

    var body: some View {
        Form {
            // MARK: Enable / Status
            Section {
                Toggle("Enable MCP Server", isOn: $mcpServer.isEnabled)
            } header: {
                Text("Server Status")
            } footer: {
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(mcpServer.isRunning ? .green : .red)
                        .font(.caption2)
                    Text(mcpServer.statusText)
                        .font(.caption)
                }
            }

            // MARK: Transport Picker
            Section("Transport") {
                Picker("Mode", selection: $mcpServer.transportType) {
                    ForEach(MCPTransportType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: mcpServer.transportType) { _, _ in
                    guard mcpServer.isRunning else { return }
                    mcpServer.stop()
                    Task { await mcpServer.start() }
                }
            }

            // MARK: Mode-specific Configuration
            switch mcpServer.transportType {
            case .http:
                httpConfigSection
            case .unixSocket:
                udsConfigSection
            }

            // MARK: Tools Reference
            Section("Available Tools (15)") {
                VStack(alignment: .leading, spacing: 12) {
                    toolGroup("Objectives", tools: [
                        ("list.bullet", "list_objectives", "List all objectives"),
                        ("plus.circle", "create_objective", "Create new objective"),
                        ("pencil.circle", "update_objective", "Update objective fields"),
                        ("archivebox", "delete_objective", "Archive an objective"),
                    ])
                    toolGroup("Key Results", tools: [
                        ("list.bullet", "list_key_results", "List KRs for objective"),
                        ("plus.circle", "create_key_result", "Create key result"),
                        ("pencil.circle", "update_key_result", "Update KR fields"),
                        ("trash", "delete_key_result", "Delete key result"),
                    ])
                    toolGroup("Tasks", tools: [
                        ("list.bullet", "list_tasks", "List tasks for KR (Markdown notes)"),
                        ("plus.circle", "create_task", "Create task with Markdown notes"),
                        ("pencil.circle", "update_task", "Update task fields & notes"),
                        ("trash", "delete_task", "Delete task"),
                    ])
                    toolGroup("Reviews", tools: [
                        ("list.bullet", "list_reviews", "List reviews for objective"),
                        ("doc.text.magnifyingglass", "get_review", "Get full review detail"),
                        ("plus.circle", "create_review", "Create review with KR entries"),
                    ])
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - HTTP Section

    private var httpConfigSection: some View {
        Section("HTTP Configuration") {
            TextField("Port", value: $savedPort, formatter: portFormatter)
                .onChange(of: savedPort) { _, newValue in
                    let wasRunning = mcpServer.isRunning
                    if wasRunning { mcpServer.stop() }
                    mcpServer.port = newValue
                    if wasRunning { Task { await mcpServer.start() } }
                }

            Label("MCP (Model Context Protocol) lets AI assistants like Claude directly read and manage your OKRs.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            endpointRow(
                label: "Endpoint",
                value: "http://localhost:\(savedPort)/mcp"
            )

            configSnippet("""
            {
              "mcpServers": {
                "solo-okrs": {
                  "url": "http://localhost:\(savedPort)/mcp"
                }
              }
            }
            """, caption: "Claude Desktop Config")
        }
    }

    // MARK: - UDS Section

    private var udsConfigSection: some View {
        Section("Unix Socket Configuration") {
            Label("Unix Domain Socket transport provides lower latency than HTTP. Ideal for local tools like Claude Code.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            endpointRow(
                label: "Socket Path",
                value: mcpServer.socketPath
            )

            configSnippet("""
            {
              "mcpServers": {
                "solo-okrs": {
                  "command": "nc",
                  "args": ["-U", "\(mcpServer.socketPath)"]
                }
              }
            }
            """,
            caption: "Claude Desktop Config (stdio via netcat)")
        }
    }

    // MARK: - Helpers

    private func endpointRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.bold())
            HStack {
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                Spacer()
                Button {
                    copyToClipboard(value)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Copy")
            }
            .padding(8)
            .background(.quaternary.opacity(0.5))
            .cornerRadius(6)
        }
    }

    private func copyToClipboard(_ value: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #elseif canImport(UIKit)
        UIPasteboard.general.string = value
        #endif
    }

    private func configSnippet(_ text: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.caption.bold())
            Text(text)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5))
                .cornerRadius(6)
        }
    }

    private var portFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.usesGroupingSeparator = false
        return f
    }

    @ViewBuilder
    private func toolGroup(_ title: String, tools: [(icon: String, name: String, desc: String)]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            ForEach(tools, id: \.name) { tool in
                HStack(spacing: 6) {
                    Image(systemName: tool.icon)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .frame(width: 14)
                    Text(tool.name)
                        .font(.system(.caption2, design: .monospaced))
                    Text("— \(tool.desc)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

#Preview {
    MCPSettingsView()
}
