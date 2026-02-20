// SplashCodeSyntaxHighlighter.swift
// SoloOKRs
//
// Custom syntax highlighter using Splash for MarkdownUI

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
        private var accumulatedText: [Text] = []
        
        init(theme: Splash.Theme) {
            self.theme = theme
            self.accumulatedText = []
        }
        
        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = color(for: type)
            accumulatedText.append(Text(token).foregroundColor(color))
        }
        
        mutating func addPlainText(_ text: String) {
            accumulatedText.append(Text(text))
        }
        
        mutating func addWhitespace(_ whitespace: String) {
            accumulatedText.append(Text(whitespace))
        }
        
        func build() -> Text {
            var result = Text("")
            for part in accumulatedText {
                result = result + part
            }
            return result
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
