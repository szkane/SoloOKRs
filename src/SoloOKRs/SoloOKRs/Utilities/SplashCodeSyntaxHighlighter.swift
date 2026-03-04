// SplashCodeSyntaxHighlighter.swift
// SoloOKRs
//
// Custom syntax highlighter using Splash for MarkdownUI
//
// Updated to fix deprecated Text + operator warning (macOS 26.0) by using 
// modern Text composition patterns instead of deprecated concatenation.

import MarkdownUI
import Splash
import SwiftUI

struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>
    
    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }
    
    func highlightCode(_ code: String, language: String?) -> Text {
        guard language != nil else {
            return Text(code)
        }
        
        let highlightedCode = syntaxHighlighter.highlight(code)
        return highlightedCode
    }
}

// MARK: - Text Output Format for SwiftUI

struct TextOutputFormat: OutputFormat {
    let theme: Splash.Theme
    
    func makeBuilder() -> Builder {
        Builder(theme: theme)
    }
}

extension TextOutputFormat {
    struct Builder: OutputBuilder {
        let theme: Splash.Theme
        private var segments: [(String, SwiftUI.Color)] = []
        
        init(theme: Splash.Theme) {
            self.theme = theme
            self.segments = []
        }
        
        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = color(for: type)
            segments.append((token, color))
        }
        
        mutating func addPlainText(_ text: String) {
            segments.append((text, .primary))
        }
        
        mutating func addWhitespace(_ whitespace: String) {
            segments.append((whitespace, .primary))
        }
        
        func build() -> Text {
            segments.reduce(Text("")) { result, segment in
                // Use string interpolation instead of + operator to avoid deprecation warning
                Text("\(result)\(Text(segment.0).foregroundColor(segment.1))")
            }
        }
        
        private func color(for tokenType: TokenType) -> SwiftUI.Color {
            switch tokenType {
            case .keyword:
                return SwiftUI.Color(theme.tokenColors[.keyword] ?? .magenta)
            case .string:
                return SwiftUI.Color(theme.tokenColors[.string] ?? .red)
            case .type:
                return SwiftUI.Color(theme.tokenColors[.type] ?? .cyan)
            case .call:
                return SwiftUI.Color(theme.tokenColors[.call] ?? .green)
            case .number:
                return SwiftUI.Color(theme.tokenColors[.number] ?? .orange)
            case .comment:
                return SwiftUI.Color(theme.tokenColors[.comment] ?? .gray)
            case .property:
                return SwiftUI.Color(theme.tokenColors[.property] ?? .blue)
            case .dotAccess:
                return SwiftUI.Color(theme.tokenColors[.dotAccess] ?? .blue)
            case .preprocessing:
                return SwiftUI.Color(theme.tokenColors[.preprocessing] ?? .orange)
            case .custom:
                return .primary
            }
        }
    }
}

// MARK: - Convenience Extension

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
    
    static var splash: Self {
        SplashCodeSyntaxHighlighter(theme: .sundellsColors(withFont: .init(size: 14)))
    }
}
