# SoloOKRs Project Overview

SoloOKRs is a personal OKR (Objectives and Key Results) management application designed specifically for macOS. It provides a robust framework for setting, tracking, and reviewing goals with integrated AI assistance and external tool connectivity via the Model Context Protocol (MCP).

## 🚀 Main Technologies & Architecture

- **Platform:** macOS (Swift, SwiftUI)
- **Persistence:** **SwiftData** with **CloudKit** synchronization support.
- **Networking:** **SwiftNIO** for the built-in MCP server.
- **Security:** **Keychain** (`kSecUseDataProtectionKeychain`) for secure API key storage.
- **UI:** 3-column `NavigationSplitView` following Apple-native design principles.
- **i18n:** Full multilingual support for 9 languages (en, zh-Hans, zh-Hant, ja, ko, de, fr, es, pt-BR).
- **AI Integration:** Support for multiple providers (Gemini, OpenAI, Anthropic, Ollama, LM Studio).
- **MCP Server:** Built-in server supporting both **HTTP** and **Unix Domain Sockets (UDS)** for integration with external tools like Claude Desktop.

## 🛠 Building and Running

### Build the Project

To build the macOS application from the command line:

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'
```

### Run Tests

To execute the test suite:

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

### Build Log and Error Check

A common pattern for quick build verification:

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64' > /tmp/build_log.txt 2>&1 || grep -A 5 -B 5 "error:" /tmp/build_log.txt
```

## 📋 Development Conventions

### 🧠 Workflow & Planning

- **Planning First:** Always create a detailed plan in `docs/plans/` using the `YYYY-MM-DD-goal.md` format before starting implementation.
- **Status Tracking:** Maintain `docs/CHECKPOINT.md` as the source of truth for the current project state, build status, and completed milestones.
- **Build Status:** Never start new features if the "Build Status" in `CHECKPOINT.md` is ❌.

### 🌐 Multilingual & UI/UX

- **Localization:** Use `Localizable.xcstrings` and `\.locale` environment injections. All UI text must be adapted for length across supported languages.
- **Apple-Native:** Adhere to macOS-native UI patterns (padding, hover states, SF Symbols, etc.).
- **Markdown:** Use `MarkdownUI` for rendering tasks and review notes with **Splash** for code syntax highlighting.

### 🛡 Security & Concurrency

- **Keychain:** Sensitive data (API keys) MUST be stored in the Keychain.
- **MCP Delegate Pattern:** Use Delegate patterns for the MCP server to avoid memory leaks or `EXC_BAD_ACCESS` when capturing state in closures.

## 📂 Key Files & Directories

- `src/SoloOKRs/SoloOKRs/SoloOKRsApp.swift`: Application entry point and shared `ModelContainer` configuration.
- `src/SoloOKRs/SoloOKRs/ContentView.swift`: Main 3-column UI structure.
- `src/SoloOKRs/SoloOKRs/Models/`: SwiftData model definitions (`Objective`, `KeyResult`, `OKRTask`, `OKRReview`, `KRReviewEntry`).
- `src/SoloOKRs/SoloOKRs/Services/MCPServer/`: Core MCP server implementation (`MCPServer.swift`, `MCPRouter.swift`).
- `src/SoloOKRs/SoloOKRs/Services/AIProvider/`: AI service abstractions and provider implementations.
- `docs/CHECKPOINT.md`: Real-time project status and historical session notes.
- `.agents/rules/`: Specialized agent instructions for session initialization and progress syncing.
