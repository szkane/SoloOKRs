// MCPServer.swift
// SoloOKRs
//
// MCP server manager using SwiftNIO — supports HTTP and Unix Domain Socket transports

import Foundation
import SwiftData
import SwiftUI

// MARK: - Transport Type

enum MCPTransportType: String, CaseIterable, Identifiable {
    case http = "http"
    case unixSocket = "unixSocket"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .http: return "HTTP"
        case .unixSocket: return "Unix Socket"
        }
    }
}

// MARK: - MCPServer

@Observable
@MainActor
class MCPServer {
    static let shared = MCPServer()

    var isRunning = false
    var port: Int = 5100
    var transportType: MCPTransportType = .http

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

    // Servers — only one active at a time
    private var httpServer: NIOHTTPServer?
    private var udsServer: NIOUDSServer?
    private var router: MCPRouter?

    // Status tracking
    var lastError: String?

    /// Default socket path under Application Support
    static var defaultSocketPath: String {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("SoloOKRs")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("mcp.sock").path
    }

    var socketPath: String = MCPServer.defaultSocketPath

    private init() {
        let savedEnabled = UserDefaults.standard.bool(forKey: "mcpServerEnabled")
        let savedPort = UserDefaults.standard.integer(forKey: "mcpServerPort")
        if savedPort > 0 { self.port = savedPort }

        if let savedTransport = UserDefaults.standard.string(forKey: "mcpTransportType"),
           let t = MCPTransportType(rawValue: savedTransport) {
            self.transportType = t
        }

        // Restore toggle state — don't start yet (router not configured)
        self.isEnabled = savedEnabled
    }

    /// Configure the server with ModelContext. Must be called before starting.
    func configure(modelContext: ModelContext) {
        self.router = MCPRouter(modelContext: modelContext)
        if isEnabled {
            Task { @MainActor in await start() }
        }
    }

    // MARK: - Delegate

    struct ServerDelegate: MCPDelegate {
        let router: MCPRouter

        func handlePOST(bytes: [UInt8]) async throws -> Data {
            let data = Data(bytes)

            do {
                print("MCP raw input bytes: \(bytes.count)")

                guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let request = JSONRPCRequest(from: dict) else {
                    return try errorResponse(code: -32700, message: "Invalid JSON-RPC request")
                }
                print("MCP request: \(request.method)")

                // Handle static methods directly — no MainActor hop needed
                if request.method == "initialize" {
                    let result: [String: Any] = [
                        "jsonrpc": "2.0",
                        "id": request.id ?? NSNull(),
                        "result": [
                            "protocolVersion": "2024-11-05",
                            "capabilities": ["tools": ["listChanged": true]],
                            "serverInfo": ["name": "SoloOKRs", "version": "1.0.0"]
                        ]
                    ]
                    return try JSONSerialization.data(withJSONObject: result)

                } else if request.method == "notifications/initialized" {
                    // This is a notification — no response expected
                    return Data()

                } else if request.method == "tools/list" {
                    // Static tool list — handle directly without Main Actor hop
                    let result: [String: Any] = [
                        "jsonrpc": "2.0",
                        "id": request.id ?? NSNull(),
                        "result": ["tools": Self.staticToolDefinitions()]
                    ]
                    return try JSONSerialization.data(withJSONObject: result)
                }

                let response = await router.handle(request: request)
                return try JSONSerialization.data(withJSONObject: response)
            } catch {
                print("MCP error: \(error)")
                return try errorResponse(code: -32700, message: "Parse error: \(error.localizedDescription)")
            }
        }

        func handleSSE(send: @escaping @Sendable (String) -> Void) {
            // SSE not implemented yet
        }

        private func errorResponse(code: Int, message: String) throws -> Data {
            let resp: [String: Any] = [
                "jsonrpc": "2.0",
                "error": ["code": code, "message": message],
                "id": NSNull()
            ]
            return try JSONSerialization.data(withJSONObject: resp)
        }

        // Static tool schema — mirrors MCPRouter.toolDefinitions()
        static func staticToolDefinitions() -> [[String: Any]] {
            func tool(_ name: String, _ desc: String, props: [String: [String: String]], required: [String]) -> [String: Any] {
                ["name": name, "description": desc, "inputSchema": ["type": "object", "properties": props, "required": required] as [String: Any]]
            }
            return [
                tool("list_objectives", "List all OKR objectives with status, progress, review count, and last reviewed date.", props: [:], required: []),
                tool("create_objective", "Create a new OKR objective (defaults to Draft status).",
                     props: ["title": ["type": "string", "description": "Title of the objective"],
                             "description": ["type": "string", "description": "Detailed description"]],
                     required: ["title"]),
                tool("update_objective", "Update an existing objective's fields.",
                     props: ["id": ["type": "string", "description": "UUID of the objective"],
                             "title": ["type": "string", "description": "New title"],
                             "description": ["type": "string", "description": "New description"],
                             "status": ["type": "string", "description": "New status: draft, active, review, achieved, archived"]],
                     required: ["id"]),
                tool("delete_objective", "Archive an objective (soft delete).",
                     props: ["id": ["type": "string", "description": "UUID of the objective"]], required: ["id"]),
                tool("list_key_results", "List key results for an objective.",
                     props: ["objective_id": ["type": "string", "description": "UUID of the parent objective"]], required: ["objective_id"]),
                tool("create_key_result", "Create a new key result under an objective.",
                     props: ["objective_id": ["type": "string", "description": "UUID of the parent objective"],
                             "title": ["type": "string", "description": "Title of the key result"]],
                     required: ["objective_id", "title"]),
                tool("update_key_result", "Update an existing key result.",
                     props: ["id": ["type": "string", "description": "UUID of the key result"],
                             "title": ["type": "string", "description": "New title"],
                             "self_score": ["type": "integer", "description": "Self-assessment score 0-100"]],
                     required: ["id"]),
                tool("delete_key_result", "Delete a key result.",
                     props: ["id": ["type": "string", "description": "UUID of the key result"]], required: ["id"]),
                tool("list_tasks", "List tasks for a key result.",
                     props: ["key_result_id": ["type": "string", "description": "UUID of the parent key result"]], required: ["key_result_id"]),
                tool("create_task", "Create a new task under a key result.",
                     props: ["key_result_id": ["type": "string", "description": "UUID of the parent key result"],
                             "title": ["type": "string", "description": "Title of the task"],
                             "taskDescription": ["type": "string", "description": "Notes for the task. Supports GitHub-flavored Markdown (GFM): bold, italic, bullet lists, numbered lists, code blocks (fenced with ```), inline code, links, and blockquotes."],
                             "priority": ["type": "string", "description": "Priority: low, medium, high, urgent"]],
                     required: ["key_result_id", "title"]),
                tool("update_task", "Update an existing task.",
                     props: ["id": ["type": "string", "description": "UUID of the task"],
                             "title": ["type": "string", "description": "New title"],
                             "taskDescription": ["type": "string", "description": "Updated notes for the task. Supports GitHub-flavored Markdown (GFM): bold, italic, bullet lists, numbered lists, code blocks (fenced with ```), inline code, links, and blockquotes."],
                             "is_completed": ["type": "boolean", "description": "Mark task as completed or not"],
                             "priority": ["type": "string", "description": "Priority: low, medium, high, urgent"]],
                     required: ["id"]),
                tool("delete_task", "Delete a task.",
                     props: ["id": ["type": "string", "description": "UUID of the task"]], required: ["id"]),
                // Reviews
                tool("list_reviews", "List all reviews for a specific objective, ordered by most recent first.",
                     props: ["objective_id": ["type": "string", "description": "UUID of the objective"]], required: ["objective_id"]),
                tool("get_review", "Get full detail of a review including all KR entries (status, trend, progress, blockers, next steps).",
                     props: ["id": ["type": "string", "description": "UUID of the review"]], required: ["id"]),
                tool("create_review", "Create a new review for an objective. Optionally include per-KR entries as a JSON array string in kr_entries.",
                     props: ["objective_id": ["type": "string", "description": "UUID of the objective to review"],
                             "review_type": ["type": "string", "description": "Type: weekly, midCycle, endCycle (default: weekly)"],
                             "overall_notes": ["type": "string", "description": "Overall review notes and summary (supports Markdown)"],
                             "kr_entries": ["type": "string", "description": "JSON array string of KR entries. Each: {\"kr_id\":\"uuid\",\"status\":\"onTrack|atRisk|offTrack|blocked\",\"trend\":\"up|down|flat\",\"completion_percent\":75,\"current_value\":75,\"target_value\":100,\"progress\":\"...\",\"blockers\":\"...\",\"next_steps\":\"...\",\"adjustment_notes\":\"...\",\"status_reason\":\"\"}"]],
                     required: ["objective_id"]),
            ]
        }
    }

    // MARK: - Start / Stop

    func start() async {
        guard !isRunning else { return }
        guard let router = router else {
            lastError = "ModelContext not configured"
            return
        }

        // Persist transport choice
        UserDefaults.standard.set(transportType.rawValue, forKey: "mcpTransportType")

        let delegate = ServerDelegate(router: router)

        do {
            switch transportType {
            case .http:
                let server = NIOHTTPServer(port: port, delegate: delegate)
                try await server.start()
                self.httpServer = server

            case .unixSocket:
                let server = NIOUDSServer(socketPath: socketPath, delegate: delegate)
                try await server.start()
                self.udsServer = server
            }

            self.isRunning = true
            self.lastError = nil
            print("MCPServer started (\(transportType.displayName))")
        } catch {
            self.lastError = error.localizedDescription
            print("MCPServer failed to start: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }

        httpServer?.stop()
        httpServer = nil

        udsServer?.stop()
        udsServer = nil

        isRunning = false
        print("MCPServer stopped")
    }

    // MARK: - Status

    var statusText: String {
        if isRunning {
            switch transportType {
            case .http:
                return "Running on localhost:\(port)"
            case .unixSocket:
                return "Running on \(socketPath)"
            }
        } else if let error = lastError {
            return "Error: \(error)"
        } else {
            return "Stopped"
        }
    }
}
