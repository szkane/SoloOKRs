// NIOUDSServer.swift
// SoloOKRs
//
// Unix Domain Socket server for MCP (alternative to HTTP transport)

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

/// HTTP-over-UDS server using SwiftNIO (Unix Domain Socket transport)
final class NIOUDSServer: @unchecked Sendable {
    private let socketPath: String
    private var channel: Channel?
    private var group: MultiThreadedEventLoopGroup?

    private let delegate: MCPDelegate

    init(socketPath: String, delegate: MCPDelegate) {
        self.socketPath = socketPath
        self.delegate = delegate
    }

    /// Start the server, binding to the Unix Domain Socket path.
    /// Removes any existing socket file first to avoid EADDRINUSE.
    func start() async throws {
        // Remove stale socket file
        try? FileManager.default.removeItem(atPath: socketPath)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group

        let delegate = self.delegate

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .childChannelInitializer { channel in
                // No HTTP pipeline — raw newline-delimited JSON (MCP stdio transport)
                channel.pipeline.addHandler(UDSChannelHandler(delegate: delegate))
            }
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 1)

        let address = try SocketAddress(unixDomainSocketPath: socketPath)
        let channel = try await bootstrap.bind(to: address).get()
        self.channel = channel

        print("NIOUDSServer started at \(socketPath)")
    }

    /// Stop the server and clean up the socket file.
    func stop() {
        channel?.close(promise: nil)
        channel = nil

        try? group?.syncShutdownGracefully()
        group = nil

        try? FileManager.default.removeItem(atPath: socketPath)

        print("NIOUDSServer stopped")
    }

    var isRunning: Bool {
        channel?.isActive ?? false
    }
}
