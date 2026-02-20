// UDSChannelHandler.swift
// SoloOKRs
//
// Raw newline-delimited JSON-RPC handler for Unix Domain Socket (stdio MCP transport)
// Unlike HTTPRequestHandler, this speaks plain JSON separated by newlines — no HTTP framing.

import Foundation
import NIOCore

/// Handles a persistent Unix Domain Socket connection using newline-delimited JSON-RPC.
/// Each request is a single JSON object followed by `\n`.
/// Each response is a single JSON object followed by `\n`.
/// The connection stays open for the session lifetime (like stdio).
final class UDSChannelHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private var lineBuffer = ""
    private let delegate: MCPDelegate

    init(delegate: MCPDelegate) {
        self.delegate = delegate
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buf = unwrapInboundIn(data)
        guard let chunk = buf.readString(length: buf.readableBytes) else { return }
        lineBuffer += chunk

        // Process one complete line at a time (split on \n)
        while let range = lineBuffer.range(of: "\n") {
            let line = String(lineBuffer[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            lineBuffer = String(lineBuffer[range.upperBound...])
            guard !line.isEmpty else { continue }
            processLine(line, channel: context.channel)
        }
    }

    private func processLine(_ line: String, channel: Channel) {
        let bytes = Array(line.utf8)
        Task { @Sendable [bytes] in
            do {
                let responseData = try await self.delegate.handlePOST(bytes: bytes)
                // Empty data = notification (no response expected)
                guard !responseData.isEmpty else { return }

                channel.eventLoop.execute {
                    guard channel.isActive else { return }
                    var out = channel.allocator.buffer(capacity: responseData.count + 1)
                    out.writeBytes(responseData)
                    out.writeString("\n")
                    channel.writeAndFlush(NIOAny(out), promise: nil)
                }
            } catch {
                let errLine = """
                    {"jsonrpc":"2.0","error":{"code":-32603,"message":"\(error.localizedDescription)"},"id":null}\n
                    """
                channel.eventLoop.execute {
                    guard channel.isActive else { return }
                    var out = channel.allocator.buffer(capacity: errLine.utf8.count)
                    out.writeString(errLine)
                    channel.writeAndFlush(NIOAny(out), promise: nil)
                }
            }
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("UDSChannelHandler error: \(error)")
        context.close(promise: nil)
    }
}
