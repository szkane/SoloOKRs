// ThinkingBlockParser.swift
// SoloOKRs
//
// Parses AI response text to extract <think>...</think> blocks
// for collapsible display in the UI.

import Foundation

/// Represents a segment of an AI response — either normal content or a thinking block.
struct AIResponseSegment: Identifiable {
    let id = UUID()
    
    enum Kind {
        case content
        case thinking
    }
    
    let kind: Kind
    let text: String
    /// `false` when a `<think>` tag opened but `</think>` hasn't arrived yet (streaming in progress)
    let isComplete: Bool
}

/// Splits AI response text into content and thinking segments.
///
/// Handles:
/// - `<think>...</think>` blocks (DeepSeek, QwQ, etc.)
/// - In-progress thinking blocks during streaming (open `<think>` without closing `</think>`)
/// - Multiple thinking blocks in a single response
/// - Nested or malformed tags gracefully
enum ThinkingBlockParser {

    static func parse(_ text: String) -> [AIResponseSegment] {
        guard !text.isEmpty else { return [] }
        
        var segments: [AIResponseSegment] = []
        var remaining = text[text.startIndex...]
        
        while !remaining.isEmpty {
            // Look for the next <think> tag
            if let thinkStart = remaining.range(of: "<think>", options: .caseInsensitive) {
                // Capture any content before the <think> tag
                let before = String(remaining[remaining.startIndex..<thinkStart.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !before.isEmpty {
                    segments.append(AIResponseSegment(kind: .content, text: before, isComplete: true))
                }
                
                // Find the closing </think> tag
                let afterTag = remaining[thinkStart.upperBound...]
                if let thinkEnd = afterTag.range(of: "</think>", options: .caseInsensitive) {
                    // Complete thinking block
                    let thinkContent = String(afterTag[afterTag.startIndex..<thinkEnd.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !thinkContent.isEmpty {
                        segments.append(AIResponseSegment(kind: .thinking, text: thinkContent, isComplete: true))
                    }
                    remaining = afterTag[thinkEnd.upperBound...]
                } else {
                    // Open thinking block — still streaming
                    let thinkContent = String(afterTag)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !thinkContent.isEmpty {
                        segments.append(AIResponseSegment(kind: .thinking, text: thinkContent, isComplete: false))
                    } else {
                        // Tag just opened, no content yet
                        segments.append(AIResponseSegment(kind: .thinking, text: "", isComplete: false))
                    }
                    remaining = afterTag[afterTag.endIndex...]
                }
            } else {
                // No more <think> tags — rest is content
                let content = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    segments.append(AIResponseSegment(kind: .content, text: content, isComplete: true))
                }
                break
            }
        }
        
        return segments
    }
}
