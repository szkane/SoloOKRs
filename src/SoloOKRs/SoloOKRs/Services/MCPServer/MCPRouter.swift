// MCPRouter.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import Foundation
import SwiftData

struct JSONRPCRequest: Codable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable?
    let id: AnyCodable?
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String = "2.0"
    let result: AnyCodable?
    let error: JSONRPCError?
    let id: AnyCodable?
}

struct JSONRPCError: Codable {
    let code: Int
    let message: String
}

// Wrapper to handle flexible JSON types
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode(Bool.self) { value = x }
        else if let x = try? container.decode([String: AnyCodable].self) { value = x.mapValues { $0.value } }
        else if let x = try? container.decode([AnyCodable].self) { value = x.map { $0.value } }
        else { 
            value = () 
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let x = value as? Int { try container.encode(x) }
        else if let x = value as? Double { try container.encode(x) }
        else if let x = value as? String { try container.encode(x) }
        else if let x = value as? Bool { try container.encode(x) }
        else if let x = value as? [String: Any] { 
            // Simplified: Encoding generic dictionaries is hard in Swift without type erasure wrappers
            // For now, we mainly output specific structs, so this might be rarely used for 'value' outgoing
            try container.encode("\(x)") 
        }
        else { try container.encodeNil() }
    }
}

@MainActor
class MCPRouter {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func handle(request: JSONRPCRequest) async -> JSONRPCResponse {
        do {
            switch request.method {
            case "initialize":
                return success(id: request.id, result: [
                    "protocolVersion": "2024-11-05",
                    "capabilities": [
                        "tools": ["listChanged": true]
                    ],
                    "serverInfo": [
                        "name": "SoloOKRs",
                        "version": "1.0.0"
                    ]
                ])
                
            case "notifications/initialized":
                // No response needed for notifications, but we acknowledge it logic-wise
                return success(id: request.id, result: "ok")
                
            case "tools/list":
                return success(id: request.id, result: [
                    "tools": [
                        [
                            "name": "list_objectives",
                            "description": "List all OKR Objectives.",
                            "inputSchema": [
                                "type": "object",
                                "properties": [:],
                                "required": []
                            ]
                        ],
                        [
                            "name": "create_objective",
                            "description": "Create a new OKR Objective.",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "title": ["type": "string", "description": "Title of the objective"],
                                    "description": ["type": "string", "description": "Detailed description"]
                                ],
                                "required": ["title", "description"]
                            ]
                        ]
                    ]
                ])
                
            case "tools/call":
                return try await handleToolCall(request)
                
            default:
                return error(id: request.id, code: -32601, message: "Method not found: \(request.method)")
            }
        } catch {
            return self.error(id: request.id, code: -32000, message: error.localizedDescription)
        }
    }
    
    private func handleToolCall(_ request: JSONRPCRequest) async throws -> JSONRPCResponse {
        guard let paramsDict = request.params?.value as? [String: Any],
              let name = paramsDict["name"] as? String,
              let arguments = paramsDict["arguments"] as? [String: Any] else {
            return error(id: request.id, code: -32602, message: "Invalid params")
        }
        
        switch name {
        case "list_objectives":
            let descriptor = FetchDescriptor<Objective>()
            let objectives = try modelContext.fetch(descriptor)
            let result = objectives.map { obj in
                [
                    "id": obj.id.uuidString,
                    "title": obj.title,
                    "status": obj.status.rawValue
                ]
            }
            return success(id: request.id, result: ["content": [["type": "text", "text": "\(result)"]]])
            
        case "create_objective":
            guard let title = arguments["title"] as? String,
                  let desc = arguments["description"] as? String else {
                return error(id: request.id, code: -32602, message: "Missing title or description")
            }
            
            let newObj = Objective(
                title: title,
                objectiveDescription: desc,
                startDate: Date(),
                endDate: Date().addingTimeInterval(90*24*3600),
                status: .active,
                order: 0
            )
            modelContext.insert(newObj)
            
            return success(id: request.id, result: ["content": [["type": "text", "text": "Created Objective: \(newObj.id.uuidString)"]]])
            
        default:
            return error(id: request.id, code: -32601, message: "Tool not found: \(name)")
        }
    }
    
    // Helpers
    private func success(id: AnyCodable?, result: Any) -> JSONRPCResponse {
        JSONRPCResponse(result: AnyCodable(result), error: nil, id: id)
    }
    
    private func error(id: AnyCodable?, code: Int, message: String) -> JSONRPCResponse {
        JSONRPCResponse(result: nil, error: JSONRPCError(code: code, message: message), id: id)
    }
}
