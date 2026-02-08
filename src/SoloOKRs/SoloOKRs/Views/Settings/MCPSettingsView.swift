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
                TextField("Port", value: $savedPort, format: .number)
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
            
            Section("What is MCP?") {
                Text("The Model Context Protocol (MCP) allows AI agents like Claude to directly access your OKRs to read, create, and update them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Link("Learn More", destination: URL(string: "https://modelcontextprotocol.io")!)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    MCPSettingsView()
}
