// MCPSettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import SwiftUI

struct MCPSettingsView: View {
    @Bindable var mcpServer = MCPServer.shared
    @AppStorage("mcpServerPort") private var savedPort = 5100
    // savedPort handles port persistence
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable MCP Server", isOn: $mcpServer.isEnabled)
            } header: {
                Text("Server Status")
            } footer: {
                HStack {
                    if mcpServer.isRunning {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.red)
                    }
                    Text(mcpServer.statusText)
                }
            }
            
            Section("Configuration") {
                TextField("Port", value: $savedPort, formatter: portFormatter)
                    .onChange(of: savedPort) { oldValue, newValue in
                        let wasRunning = mcpServer.isRunning
                        if wasRunning {
                            mcpServer.stop()
                        }
                        
                        mcpServer.port = newValue
                        
                        // Restart if enabled (which it was if wasRunning is true, mostly)
                        if wasRunning {
                            Task {
                                await mcpServer.start()
                            }
                        }
                    }
            }
            
            Section("How It Works") {
                VStack(alignment: .leading, spacing: 12) {
                    Label("MCP (Model Context Protocol) lets AI assistants like Claude directly read and manage your OKRs.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    Text("Endpoint")
                        .font(.caption.bold())
                    HStack {
                        Text("http://localhost:\(savedPort)/mcp")
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("http://localhost:\(savedPort)/mcp", forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy URL")
                    }
                    .padding(8)
                    .background(.quaternary.opacity(0.5))
                    .cornerRadius(6)
                    
                    Divider()
                    
                    Text("Available Tools (12)")
                        .font(.caption.bold())
                    
                    VStack(alignment: .leading, spacing: 8) {
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
                            ("list.bullet", "list_tasks", "List tasks for KR"),
                            ("plus.circle", "create_task", "Create task"),
                            ("pencil.circle", "update_task", "Update task fields"),
                            ("trash", "delete_task", "Delete task"),
                        ])
                    }
                    
                    Divider()
                    
                    Text("Claude Desktop Config")
                        .font(.caption.bold())
                    Text("Add this to your claude_desktop_config.json:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("""
                    {
                      "mcpServers": {
                        "solo-okrs": {
                          "url": "http://localhost:\(savedPort)/mcp"
                        }
                      }
                    }
                    """)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.5))
                        .cornerRadius(6)
                    
                    Link("Learn More about MCP", destination: URL(string: "https://modelcontextprotocol.io")!)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    /// Number formatter without grouping separator (avoids "5,100")
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
