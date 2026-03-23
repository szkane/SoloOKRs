// AIResponseView.swift
// SoloOKRs
//
// Renders AI response text with collapsible thinking blocks.
// Thinking sections are collapsed by default, shown in smaller font,
// with a pulsing brain animation while streaming.

import SwiftUI
import MarkdownUI
import Combine

struct AIResponseView: View {
    let text: String
    var isStreaming: Bool = false
    
    var body: some View {
        let segments = ThinkingBlockParser.parse(text)
        
        VStack(alignment: .leading, spacing: 12) {
            ForEach(segments) { segment in
                switch segment.kind {
                case .content:
                    Markdown(segment.text)
                        .textSelection(.enabled)
                        .markdownTheme(.gitHub)
                    
                case .thinking:
                    ThinkingBlockView(
                        text: segment.text,
                        isComplete: segment.isComplete,
                        isStreaming: isStreaming
                    )
                }
            }
        }
    }
}

// MARK: - Thinking Block View

private struct ThinkingBlockView: View {
    let text: String
    let isComplete: Bool
    let isStreaming: Bool
    
    @State private var isExpanded = false
    @State private var isPulsing = false
    
    private var showAnimation: Bool {
        !isComplete && isStreaming
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse, options: .repeating, isActive: showAnimation)
                    
                    Text(LocalizedStringKey("Thinking"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if showAnimation {
                        ThinkingDotsView()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Collapsible content
            if isExpanded {
                Divider()
                    .padding(.horizontal, 10)
                
                ScrollView {
                    Text(text)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 200)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Thinking Dots Animation

private struct ThinkingDotsView: View {
    @State private var dotCount = 0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(String(repeating: ".", count: dotCount + 1))
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 20, alignment: .leading)
            .onReceive(timer) { _ in
                dotCount = (dotCount + 1) % 3
            }
    }
}

#Preview("AI Response with Thinking") {
    ScrollView {
        AIResponseView(
            text: """
            <think>
            Let me analyze this OKR structure. The objective is clear but the key results could be more specific and measurable. I should check if they follow the SMART criteria.
            </think>
            
            ## Analysis
            
            Your OKR structure looks good overall! Here are some suggestions:
            
            1. **Make KRs more measurable** — Add specific numbers
            2. **Add time bounds** — Each KR should have a deadline
            
            <think>
            I should also mention the alignment between KRs and the objective.
            </think>
            
            ### Alignment
            
            All key results align well with the stated objective.
            """,
            isStreaming: false
        )
        .padding()
    }
    .frame(width: 500, height: 600)
}
