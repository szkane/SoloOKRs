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
    /// `false` when a thinking block is still streaming (no closing tag yet)
    let isComplete: Bool
}

/// Splits AI response text into content and thinking segments.
///
/// Handles:
/// - `<think>...</think>` blocks (DeepSeek, QwQ, etc.)
/// - Missing `<think>` opening tag (only `</think>` present) — treats start-of-text to `</think>` as thinking
/// - In-progress thinking blocks during streaming
/// - Multiple thinking blocks in a single response
/// - JSON unicode escapes for angle brackets
enum ThinkingBlockParser {
    
    /// Close tag pattern
    private static let closeTag = "</think>"
    
    /// Normalizes text that may contain JSON-escaped unicode for angle brackets.
    private static func normalizeText(_ text: String) -> String {
        return text
            // JSON unicode escapes
            .replacingOccurrences(of: "\\u003c", with: "<")
            .replacingOccurrences(of: "\\u003e", with: ">")
            .replacingOccurrences(of: "\\u003C", with: "<")
            .replacingOccurrences(of: "\\u003E", with: ">")
    }
    
    static func parse(_ text: String) -> [AIResponseSegment] {
        guard !text.isEmpty else { return [] }
        
        // Normalize any JSON-escaped angle brackets
        let normalized = normalizeText(text)
        
        let hasOpenTag = normalized.range(of: "<think>", options: .caseInsensitive) != nil
        let hasCloseTag = normalized.range(of: closeTag, options: .caseInsensitive) != nil
        
        // Case 1: No thinking tags at all — return entire text as content
        if !hasOpenTag && !hasCloseTag {
            return [AIResponseSegment(kind: .content, text: normalized, isComplete: true)]
        }
        
        // Case 2: Only </think> present (opening tag was stripped/lost)
        // Treat everything before </think> as a thinking block
        if !hasOpenTag && hasCloseTag {
            return parseWithCloseOnly(normalized)
        }
        
        // Case 3: Normal parsing with <think>...</think> pairs
        return parseNormal(normalized)
    }
    
    /// Handles the case where `</think>` exists but `<think>` doesn't.
    /// Everything from the start to `</think>` is treated as thinking.
    private static func parseWithCloseOnly(_ text: String) -> [AIResponseSegment] {
        var segments: [AIResponseSegment] = []
        var remaining = text[text.startIndex...]
        
        while !remaining.isEmpty {
            if let closeRange = remaining.range(of: closeTag, options: .caseInsensitive) {
                let thinkContent = String(remaining[remaining.startIndex..<closeRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !thinkContent.isEmpty {
                    segments.append(AIResponseSegment(kind: .thinking, text: thinkContent, isComplete: true))
                }
                remaining = remaining[closeRange.upperBound...]
                
                // Check for another </think> in remaining (recursive close tags)
                // Everything after this </think> until the next one (or end) is content
                if let nextClose = remaining.range(of: closeTag, options: .caseInsensitive) {
                    let contentBefore = String(remaining[remaining.startIndex..<nextClose.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !contentBefore.isEmpty {
                        segments.append(AIResponseSegment(kind: .content, text: contentBefore, isComplete: true))
                    }
                    let thinkAfter = String(remaining[nextClose.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !thinkAfter.isEmpty {
                        segments.append(AIResponseSegment(kind: .content, text: thinkAfter, isComplete: true))
                    }
                    break
                } else {
                    // Rest is content after the thinking block
                    let content = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        segments.append(AIResponseSegment(kind: .content, text: content, isComplete: true))
                    }
                    break
                }
            } else {
                // No more close tags — this is an in-progress thinking block
                let content = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    segments.append(AIResponseSegment(kind: .thinking, text: content, isComplete: false))
                }
                break
            }
        }
        
        return segments
    }
    
    /// Standard parsing with matched `<think>...</think>` pairs.
    private static func parseNormal(_ text: String) -> [AIResponseSegment] {
        var segments: [AIResponseSegment] = []
        var remaining = text[text.startIndex...]
        
        while !remaining.isEmpty {
            if let thinkStart = remaining.range(of: "<think>", options: .caseInsensitive) {
                // Content before <think>
                let before = String(remaining[remaining.startIndex..<thinkStart.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !before.isEmpty {
                    segments.append(AIResponseSegment(kind: .content, text: before, isComplete: true))
                }
                
                let afterTag = remaining[thinkStart.upperBound...]
                if let thinkEnd = afterTag.range(of: closeTag, options: .caseInsensitive) {
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
                    segments.append(AIResponseSegment(
                        kind: .thinking,
                        text: thinkContent,
                        isComplete: false
                    ))
                    break
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
