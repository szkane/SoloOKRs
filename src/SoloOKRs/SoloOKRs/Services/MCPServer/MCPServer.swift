// MCPServer.swift
// SoloOKRs
//
// MCP server manager using SwiftNIO

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
class MCPServer {
    static let shared = MCPServer()

    var isRunning = false
    var port: Int = 5100
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "mcpServerEnabled") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "mcpServerEnabled")
            if newValue {
                Task { await start() }
            } else {
                stop()
            }
        }
    }
    
    private var server: NIOHTTPServer?
    private var router: MCPRouter?
    
    // Status tracking
    var lastError: String?
    
    private init() {
        let savedPort = UserDefaults.standard.integer(forKey: "mcpServerPort")
        if savedPort > 0 {
            self.port = savedPort
        }
        
        // Auto-start if enabled
        if isEnabled {
            // We can't await in init, so we defer start
            Task { @MainActor in
                // Small delay to ensure configuration matches usage
                try? await Task.sleep(for: .seconds(0.5)) 
                await start()
            }
        }
    }
    
    /// Configure the server with the ModelContext for data access
    func configure(modelContext: ModelContext) {
        self.router = MCPRouter(modelContext: modelContext)
    }

    func start() async {
        guard !isRunning else { return }
        guard let router = router else {
            lastError = "ModelContext not configured"
            return 
        }

        // Capture router for async closures
        let capturedRouter = router
        
        let newServer = NIOHTTPServer(
            port: port,
            onPOST: { @Sendable [capturedRouter] data async throws -> Data in
                // Parse and handle JSON-RPC request
                let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
                let response = await capturedRouter.handle(request: request)
                return try JSONEncoder().encode(response)
            },
            onSSE: { @Sendable send in
                print("New SSE Client Connected")
                // Future: store send closure for push notifications
            }
        )
        
        do {
            try await newServer.start()
            self.server = newServer
            self.isRunning = true
            self.lastError = nil
            print("MCPServer started on port \(port)")
        } catch {
            self.lastError = error.localizedDescription
            print("MCPServer failed to start: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }

        server?.stop()
        server = nil
        isRunning = false
        print("MCPServer stopped")
    }

    var statusText: String {
        if isRunning {
            return "Running on localhost:\(port)"
        } else if let error = lastError {
            return "Error: \(error)"
        } else {
            return "Stopped"
        }
    }
}
