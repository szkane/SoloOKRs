// NIOHTTPServer.swift
// SoloOKRs
//
// SwiftNIO-based HTTP server for MCP

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

/// Delegate protocol for handling MCP requests
protocol MCPDelegate: Sendable {
    func handlePOST(bytes: [UInt8]) async throws -> Data
    func handleSSE(send: @escaping @Sendable (String) -> Void)
}

/// HTTP server using SwiftNIO for the MCP protocol
final class NIOHTTPServer: @unchecked Sendable {
    private let port: Int
    private var channel: Channel?
    private var group: MultiThreadedEventLoopGroup?
    
    private let delegate: MCPDelegate
    
    init(port: Int, delegate: MCPDelegate) {
        self.port = port
        self.delegate = delegate
    }
    
    /// Start the server on the configured port
    func start() async throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        
        let delegate = self.delegate
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(
                        HTTPRequestHandler(delegate: delegate)
                    )
                }
            }
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 1)
        
        let channel = try await bootstrap.bind(host: "127.0.0.1", port: port).get()
        self.channel = channel
        
        print("NIOHTTPServer started on port \(port)")
    }
    
    /// Stop the server and clean up resources
    func stop() {
        channel?.close(promise: nil)
        channel = nil
        
        try? group?.syncShutdownGracefully()
        group = nil
        
        print("NIOHTTPServer stopped")
    }
    
    var isRunning: Bool {
        channel?.isActive ?? false
    }
}
