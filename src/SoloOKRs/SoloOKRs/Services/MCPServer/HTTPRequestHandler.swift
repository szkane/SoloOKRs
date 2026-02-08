// HTTPRequestHandler.swift
// SoloOKRs
//
// SwiftNIO HTTP channel handler for MCP server

import Foundation
import NIOCore
import NIOHTTP1

/// Accumulates HTTP request parts and routes to the appropriate handler
final class HTTPRequestHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var requestHead: HTTPRequestHead?
    private var bodyBuffer: ByteBuffer?
    
    private let onPOST: @Sendable (Data) async throws -> Data
    private let onSSE: @Sendable (@escaping (String) -> Void) -> Void
    
    init(
        onPOST: @escaping @Sendable (Data) async throws -> Data,
        onSSE: @escaping @Sendable (@escaping (String) -> Void) -> Void
    ) {
        self.onPOST = onPOST
        self.onSSE = onSSE
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
        case (.POST, "/message"):
            handlePOSTMessage(context: context, body: body)
            
        case (.GET, "/sse"):
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
            sendResponse(context: context, status: .badRequest, body: "Missing body")
            return
        }
        
        let data = Data(body.readableBytesView)
        let channel = context.channel
        
        // Process async on a Task, then write response back
        Task { @Sendable in
            do {
                let responseData = try await self.onPOST(data)
                let responseString = String(decoding: responseData, as: UTF8.self)
                
                // Write response back on the event loop
                channel.eventLoop.execute {
                    guard channel.isActive else { return }
                    self.sendResponseOnChannel(
                        channel: channel,
                        status: .ok,
                        contentType: "application/json",
                        body: responseString
                    )
                }
            } catch {
                channel.eventLoop.execute {
                    guard channel.isActive else { return }
                    self.sendResponseOnChannel(
                        channel: channel,
                        status: .internalServerError,
                        body: error.localizedDescription
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
        
        // Provide send closure to delegate
        let channel = context.channel
        onSSE { message in
            guard channel.isActive else { return }
            channel.eventLoop.execute {
                var buffer = channel.allocator.buffer(capacity: message.utf8.count + 10)
                buffer.writeString("data: \(message)\n\n")
                channel.write(NIOAny(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)
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
        
        channel.write(NIOAny(HTTPServerResponsePart.head(head)), promise: nil)
        channel.write(NIOAny(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)
        channel.writeAndFlush(NIOAny(HTTPServerResponsePart.end(nil))).whenComplete { _ in
            channel.close(promise: nil)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("HTTPRequestHandler error: \(error)")
        context.close(promise: nil)
    }
}
