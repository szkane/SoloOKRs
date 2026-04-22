// MarkdownEditorView.swift
// SoloOKRs
//
// Markdown editor with live preview using MarkdownUI

import SwiftUI
import MarkdownUI

struct MarkdownEditorView: View {
    @Binding var text: String
    var placeholder: String = "Enter description..."
    
    @State private var showPreview = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                formatButton("Bold", icon: "bold", insert: "**", wrap: true)
                formatButton("Italic", icon: "italic", insert: "_", wrap: true)
                formatButton("Code", icon: "chevron.left.forwardslash.chevron.right", insert: "`", wrap: true)
                
                Divider().frame(height: 16)
                
                formatButton("List", icon: "list.bullet", insert: "- ", wrap: false)
                formatButton("Link", icon: "link", insert: "[text](url)", wrap: false)
                formatButton("Table", icon: "tablecells", insert: "\n| Header | Header |\n|--------|--------|\n| Cell   | Cell   |\n", wrap: false)
                
                Spacer()
                
                Toggle(isOn: $showPreview) {
                    Image(systemName: showPreview ? "eye.fill" : "eye")
                }
                .toggleStyle(.button)
                .help("Toggle Preview")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.bar)
            
            Divider()
            
            // Editor / Preview
            if showPreview {
                #if os(macOS)
                HSplitView {
                    editorPane
                    previewPane
                }
                #else
                HStack(spacing: 0) {
                    editorPane
                    Divider()
                    previewPane
                }
                #endif
            } else {
                editorPane
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
    
    // MARK: - Subviews
    
    private var editorPane: some View {
        TextEditor(text: $text)
            .font(.body.monospaced())
            .scrollContentBackground(.hidden)
            .padding(8)
            .frame(minHeight: 120)
    }
    
    private var previewPane: some View {
        ScrollView {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            } else {
                // Card container for Markdown content
                VStack(alignment: .leading, spacing: 0) {
                    Markdown(text)
                        .textSelection(.enabled)
                        .markdownTheme(.gitHub)
                        .markdownCodeSyntaxHighlighter(.splash)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(16)
            }
        }
        .frame(minHeight: 120)
        .background(.background.secondary)
    }
    
    // MARK: - Formatting
    
    private func formatButton(_ label: String, icon: String, insert: String, wrap: Bool) -> some View {
        Button {
            if wrap {
                text += "\(insert)text\(insert)"
            } else {
                text += "\n\(insert)"
            }
        } label: {
            Image(systemName: icon)
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

#Preview {
    @Previewable @State var text = """
    # Heading 1
    ## Heading 2
    
    Regular text with **bold** and _italic_.
    
    - List item 1
    - List item 2
    
    ```swift
    func hello() {
        print("Hello, World!")
    }
    ```
    
    > Blockquote
    
    [Link](https://example.com)
    """
    
    MarkdownEditorView(text: $text)
        .frame(width: 600, height: 400)
}
