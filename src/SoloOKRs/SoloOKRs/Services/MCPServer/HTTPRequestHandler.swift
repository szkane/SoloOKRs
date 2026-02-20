// HTTPRequestHandler.swift
// SoloOKRs
//
// SwiftNIO HTTP channel handler for MCP server

import Foundation
@preconcurrency import NIOCore
import NIOHTTP1

/// Accumulates HTTP request parts and routes to the appropriate handler
final class HTTPRequestHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var requestHead: HTTPRequestHead?
    private var bodyBuffer: ByteBuffer?
    
    private let delegate: MCPDelegate
    
    init(delegate: MCPDelegate) {
        self.delegate = delegate
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        
        switch part {
        case .head(let head):
            requestHead = head
            bodyBuffer = context.channel.allocator.buffer(capacity: 0)
            
        case .body(var buffer):
            bodyBuffer?.writeBuffer(&buffer)
            
        case .end:
            guard let head = requestHead else { return }
            handleRequest(context: context, head: head, body: bodyBuffer)
            requestHead = nil
            bodyBuffer = nil
        }
    }
    
    private func handleRequest(
        context: ChannelHandlerContext,
        head: HTTPRequestHead,
        body: ByteBuffer?
    ) {
        let path = head.uri.split(separator: "?").first.map(String.init) ?? head.uri
        
        switch (head.method, path) {
        case (.POST, "/mcp"), (.POST, "/message"):
            handlePOSTMessage(context: context, body: body)
            
        case (.GET, "/mcp"), (.GET, "/sse"):
            handleSSE(context: context)
            
        case (.OPTIONS, _):
            // CORS preflight
            sendResponse(context: context, status: .ok, body: "")
            
        default:
            sendResponse(context: context, status: .notFound, body: "Not Found")
        }
    }
    
    private func handlePOSTMessage(context: ChannelHandlerContext, body: ByteBuffer?) {
        guard let body = body else {
            sendResponse(context: context, status: .badRequest, contentType: "application/json", body: "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32700,\"message\":\"Missing body\"},\"id\":null}")
            return
        }
        
        // Force deep copy via Array
        let bytes = Array(body.readableBytesView)
        print("HTTPRequestHandler BEFORE TASK: \(bytes.count) bytes")
        
        // Debug: respond immediately if body is empty
        if bytes.isEmpty {
            sendResponse(
                context: context,
                status: .ok,
                contentType: "application/json",
                body: "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32700,\"message\":\"Empty body! readableBytes=\(body.readableBytes)\"},\"id\":null}"
            )
            return
        }
        
        let channel = context.channel
        
        // Process async on a Task, then write response back
        Task { @Sendable [bytes] in
            print("HTTPRequestHandler INSIDE TASK: Byte count \(bytes.count)")
            do {
                let responseData = try await self.delegate.handlePOST(bytes: bytes)
                let responseString = String(decoding: responseData, as: UTF8.self)
                
                // Write response back on the event loop
                channel.eventLoop.execute {
                    guard channel.isActive else { return }
                    if responseData.isEmpty {
                        // Notification — no body expected (e.g. notifications/initialized)
                        self.sendResponseOnChannel(
                            channel: channel,
                            status: .noContent,
                            contentType: "application/json",
                            body: ""
                        )
                    } else {
                        self.sendResponseOnChannel(
                            channel: channel,
                            status: .ok,
                            contentType: "application/json",
                            body: responseString
                        )
                    }
                }
            } catch {
                channel.eventLoop.execute {
                    guard channel.isActive else { return }
                    let errorJSON = "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"\(error.localizedDescription)\"},\"id\":null}"
                    self.sendResponseOnChannel(
                        channel: channel,
                        status: .ok,
                        contentType: "application/json",
                        body: errorJSON
                    )
                }
            }
        }
    }
    
    private func handleSSE(context: ChannelHandlerContext) {
        // Send SSE headers
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/event-stream")
        headers.add(name: "Cache-Control", value: "no-cache")
        headers.add(name: "Connection", value: "keep-alive")
        headers.add(name: "Access-Control-Allow-Origin", value: "*")
        
        let head = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        context.flush()
        
        let channel = context.channel
        
        // Send the MCP endpoint event (required by SSE transport spec)
        // This tells the client where to POST JSON-RPC messages
        channel.eventLoop.execute {
            var buffer = channel.allocator.buffer(capacity: 64)
            buffer.writeString("event: endpoint\ndata: /message\n\n")
            channel.writeHTTPPart(.body(.byteBuffer(buffer)), promise: nil)
            channel.flush()
        }
        
        // Provide send closure to delegate
        delegate.handleSSE { message in
            guard channel.isActive else { return }
            channel.eventLoop.execute {
                var buffer = channel.allocator.buffer(capacity: message.utf8.count + 10)
                buffer.writeString("data: \(message)\n\n")
                channel.writeHTTPPart(.body(.byteBuffer(buffer)), promise: nil)
                channel.flush()
            }
        }
    }
    
    private func sendResponse(
        context: ChannelHandlerContext,
        status: HTTPResponseStatus,
        contentType: String = "text/plain",
        body: String
    ) {
        sendResponseOnChannel(channel: context.channel, status: status, contentType: contentType, body: body)
    }
    
    private func sendResponseOnChannel(
        channel: Channel,
        status: HTTPResponseStatus,
        contentType: String = "text/plain",
        body: String
    ) {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: contentType)
        headers.add(name: "Content-Length", value: "\(body.utf8.count)")
        headers.add(name: "Access-Control-Allow-Origin", value: "*")
        headers.add(name: "Access-Control-Allow-Methods", value: "GET, POST, OPTIONS")
        headers.add(name: "Access-Control-Allow-Headers", value: "Content-Type")
        
        let head = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        
        var buffer = channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)
        
        channel.writeHTTPPart(.head(head), promise: nil)
        channel.writeHTTPPart(.body(.byteBuffer(buffer)), promise: nil)
        channel.writeAndFlushHTTPPart(.end(nil)).whenComplete { _ in
            channel.close(promise: nil)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("HTTPRequestHandler error: \(error)")
        context.close(promise: nil)
    }
}

// MARK: - Typed Channel Write Helpers (sync, must be called on the channel's event loop)

private extension Channel {
    /// Writes an `HTTPServerResponsePart` synchronously (must be on event loop).
    func writeHTTPPart(_ part: HTTPServerResponsePart, promise: EventLoopPromise<Void>?) {
        pipeline.syncOperations.write(NIOAny(part), promise: promise)
    }

    /// Writes and flushes an `HTTPServerResponsePart` synchronously (must be on event loop).
    @discardableResult
    func writeAndFlushHTTPPart(_ part: HTTPServerResponsePart) -> EventLoopFuture<Void> {
        pipeline.syncOperations.write(NIOAny(part), promise: nil)
        pipeline.syncOperations.flush()
        return eventLoop.makeSucceededVoidFuture()
    }
}
