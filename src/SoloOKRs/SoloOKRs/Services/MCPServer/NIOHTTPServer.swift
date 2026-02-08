// NIOHTTPServer.swift
// SoloOKRs
//
// SwiftNIO-based HTTP server for MCP

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

/// HTTP server using SwiftNIO for the MCP protocol
final class NIOHTTPServer: @unchecked Sendable {
    private let port: Int
    private var channel: Channel?
    private var group: MultiThreadedEventLoopGroup?
    
    private let onPOST: @Sendable (Data) async throws -> Data
    private let onSSE: @Sendable (@escaping (String) -> Void) -> Void
    
    init(
        port: Int,
        onPOST: @escaping @Sendable (Data) async throws -> Data,
        onSSE: @escaping @Sendable (@escaping (String) -> Void) -> Void
    ) {
        self.port = port
        self.onPOST = onPOST
        self.onSSE = onSSE
    }
    
    /// Start the server on the configured port
    func start() async throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        
        let onPOST = self.onPOST
        let onSSE = self.onSSE
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(
                        HTTPRequestHandler(onPOST: onPOST, onSSE: onSSE)
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
