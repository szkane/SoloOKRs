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
    
    var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "mcpServerEnabled")
            if isEnabled {
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
        // Load saved state without triggering didSet
        let savedEnabled = UserDefaults.standard.bool(forKey: "mcpServerEnabled")
        
        let savedPort = UserDefaults.standard.integer(forKey: "mcpServerPort")
        if savedPort > 0 {
            self.port = savedPort
        }
        
        // Just restore the toggle state — don't start yet (router not configured)
        self.isEnabled = savedEnabled
    }
    
    /// Configure the server with the ModelContext for data access.
    /// Must be called before the server can start (typically in onAppear).
    func configure(modelContext: ModelContext) {
        self.router = MCPRouter(modelContext: modelContext)
        
        // Auto-start if the toggle was saved as enabled
        if isEnabled {
            Task { @MainActor in
                await start()
            }
        }
    }

    // Delegate implementation to handle requests without closure capture issues
    struct ServerDelegate: MCPDelegate {
        let router: MCPRouter
        
        func handlePOST(bytes: [UInt8]) async throws -> Data {
            // Convert [UInt8] back to Data for processing
            let data = Data(bytes)
            
            do {
                // Debug: log raw received data
                print("MCP raw input bytes: \(bytes.count)")
                
                // Parse JSON-RPC request using JSONSerialization
                guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let request = JSONRPCRequest(from: dict) else {
                    let errorResponse: [String: Any] = [
                        "jsonrpc": "2.0",
                        "error": ["code": -32700, "message": "Invalid JSON-RPC request"],
                        "id": NSNull()
                    ]
                    return try JSONSerialization.data(withJSONObject: errorResponse)
                }
                print("MCP request: \(request.method)")
                
                // Optimization: Handle initialize/initialized directly to avoid MainActor hop if possible
                if request.method == "initialize" {
                     let response: [String: Any] = [
                        "jsonrpc": "2.0",
                        "id": request.id ?? NSNull(),
                        "result": [
                            "protocolVersion": "2024-11-05",
                            "capabilities": [
                                "tools": ["listChanged": true]
                            ],
                            "serverInfo": [
                                "name": "SoloOKRs",
                                "version": "1.0.0"
                            ]
                        ]
                    ]
                    return try JSONSerialization.data(withJSONObject: response)
                } else if request.method == "notifications/initialized" {
                    // Just ack
                     let response: [String: Any] = [
                        "jsonrpc": "2.0",
                        "id": request.id ?? NSNull(),
                        "result": "ok"
                    ]
                    return try JSONSerialization.data(withJSONObject: response)
                }
                
                let response = await router.handle(request: request)
                return try JSONSerialization.data(withJSONObject: response)
            } catch {
                print("MCP error: \(error)")
                let hexString = data.map { String(format: "%02hhx", $0) }.joined()
                let errorResponse: [String: Any] = [
                    "jsonrpc": "2.0",
                    "error": [
                        "code": -32700,
                        "message": "Parse error: \(error.localizedDescription). Build-ID: DELEGATE-FIX. Count: \(data.count). Hex: \(hexString)"
                    ],
                    "id": NSNull()
                ]
                return try JSONSerialization.data(withJSONObject: errorResponse)
            }
        }
        
        func handleSSE(send: @escaping @Sendable (String) -> Void) {
            // SSE not implemented yet
        }
    }

    func start() async {
        guard !isRunning else { return }
        guard let router = router else {
            lastError = "ModelContext not configured"
            return 
        }

        // Use delegate pattern instead of closure
        let delegate = ServerDelegate(router: router)
        
        let newServer = NIOHTTPServer(port: port, delegate: delegate)
        
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
