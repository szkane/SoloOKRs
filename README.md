<p align="center">
  <img src="src/SoloOKRs/SoloOKRs/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="SoloOKRs Icon">
</p>

<h1 align="center">SoloOKRs</h1>

<p align="center">
  <strong>A personal OKR management app for macOS — with built-in AI assistance & MCP integration</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-lightgrey" alt="License">
</p>

---

## ✨ What is SoloOKRs?

SoloOKRs is a **native macOS application** for managing personal goals using the **OKR (Objectives and Key Results)** framework. Unlike team-oriented OKR tools, SoloOKRs is designed for individuals who want a focused, distraction-free environment to set, track, and reflect on their personal goals. This project was built in a vibe-coding workflow with Google Antigravity.

What makes it special:

- 🧠 **AI-Powered Assistance** — Get AI suggestions for refining objectives, breaking down key results, and reviewing progress
- 🔌 **MCP Server** — Expose your OKR data to AI assistants like Claude Desktop via the Model Context Protocol
- 📊 **Review Mode** — Built-in retrospective workflow for periodic OKR reviews
- ☁️ **iCloud Sync** — Seamless data synchronization across your Mac devices
- 🌍 **9 Languages** — Full multilingual support with real-time language switching

---

## 🌐 Translations

This README is available in multiple languages to help developers around the world:

| Language | Link |
|----------|------|
| English | [README.md](README.md) |
| 简体中文 | [docs/README_zh.md](docs/README_zh.md) |
| 日本語 | [docs/README_ja.md](docs/README_ja.md) |
| 한국어 | [docs/README_ko.md](docs/README_ko.md) |
| Deutsch | [docs/README_de.md](docs/README_de.md) |
| Français | [docs/README_fr.md](docs/README_fr.md) |
| Español | [docs/README_es.md](docs/README_es.md) |
| Português (BR) | [docs/README_ptBR.md](docs/README_ptBR.md) |

---

## 🎯 Features

### Core OKR Management

| Feature | Description |
|---------|-------------|
| **Objectives** | Create, edit, and archive objectives with progress tracking |
| **Key Results** | Define measurable key results with different types (percentage, number, milestone) |
| **Tasks** | Break down key results into actionable tasks with Markdown descriptions |
| **Archives** | Archive completed objectives with a trophy-marked archive section |
| **Drag & Drop** | Reorder objectives and key results with drag-and-drop |

### 🧠 AI Integration

SoloOKRs includes a built-in AI assistant that can help you at every stage of the OKR lifecycle:

**Supported Providers:**

| Provider | Type | Description |
|----------|------|-------------|
| **Gemini** | Cloud | Google's Gemini models |
| **OpenAI** | Cloud | GPT-4o and other OpenAI models |
| **Anthropic** | Cloud | Claude models |
| **Ollama** | Local | Run local LLMs (Llama, Mistral, etc.) |
| **LM Studio** | Local | Local model inference server |

**How to use:**

1. Open **Settings → AI** and select your preferred provider
2. Enter your API key (stored securely in macOS Keychain)
3. For local providers (Ollama/LM Studio), ensure the server is running on your machine
4. Use the AI sparkle button (✦) in objective and key result views to get suggestions
5. AI responses include **thinking block** visualization — collapsible blocks that show the AI's reasoning process

### 🔌 MCP Server (Model Context Protocol)

SoloOKRs includes a built-in **MCP server** that exposes your OKR data to external AI assistants. This enables tools like **Claude Desktop** to read and manipulate your goals directly.

**Transport Options:**

| Transport | Protocol | Use Case |
|-----------|----------|----------|
| **HTTP** | `http://localhost:<port>` | Universal access, web-based tools |
| **Unix Domain Sockets** | `/tmp/solookrs.sock` | Claude Desktop, local tools (lower latency) |

**Available MCP Tools (12 tools):**

| Category | Tools |
|----------|-------|
| **Objectives** | `list_objectives`, `get_objective`, `create_objective`, `update_objective`, `delete_objective` |
| **Key Results** | `list_key_results`, `update_key_result` |
| **Tasks** | `list_tasks`, `create_task`, `update_task` |
| **Reviews** | `list_reviews`, `get_review`, `create_review` |

**Claude Desktop Integration:**

To connect SoloOKRs with Claude Desktop, add the following to your Claude Desktop configuration (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "solookrs": {
      "command": "nc",
      "args": ["-U", "/tmp/solookrs.sock"]
    }
  }
}
```

Or for HTTP transport:

```json
{
  "mcpServers": {
    "solookrs": {
      "url": "http://localhost:8716"
    }
  }
}
```

**How to enable:**

1. Open **Settings → MCP**
2. Toggle the MCP server on
3. Choose your transport (HTTP or Unix Socket)
4. Configure Claude Desktop with the connection details above
5. The status indicator in the sidebar shows connection state

### 📊 Review Mode

SoloOKRs includes a structured **review/retrospective** workflow:

1. **Create a Review** — Select an objective and generate a review entry
2. **KR Assessment** — Rate each key result's progress with notes
3. **AI Summary** — Optionally generate an AI-powered review summary
4. **Review History** — Browse and revisit past reviews over time
5. **Markdown Notes** — Write rich review notes with full Markdown + code syntax highlighting

### 🎨 Customizable AI Prompts

Tailor the AI's behavior through **Settings → Prompts**:

- Customize system prompts for objective suggestions
- Adjust key result generation prompts
- Modify review summary prompt templates
- All prompts support Markdown formatting

---

## 🏗 Architecture

```
SoloOKRs/
├── Models/           # SwiftData model definitions
│   ├── Objective     # Top-level goals
│   ├── KeyResult     # Measurable outcomes
│   ├── OKRTask       # Actionable items
│   ├── OKRReview     # Review sessions
│   └── KRReviewEntry # Per-KR review entries
├── Views/
│   ├── Objectives/   # Sidebar — Objective list & management
│   ├── KeyResults/   # Middle column — KR cards & creation
│   ├── Tasks/        # Detail column — Task list & editors
│   ├── Reviews/      # Review creation & history
│   ├── Settings/     # Settings tabs (General, AI, Prompts, MCP, Sync)
│   └── Components/   # Shared components (AIResponseView, MarkdownEditor)
├── Services/
│   ├── AIProvider/   # AIService, PromptManager, provider abstractions
│   └── MCPServer/    # SwiftNIO-based MCP server (HTTP + UDS)
└── Utilities/        # Keychain, Markdown parsing, syntax highlighting
```

**UI Layout:** 3-column `NavigationSplitView`
- **Column 1 (Sidebar):** Objective list with status bar (AI/MCP/Sync indicators)
- **Column 2 (Content):** Key results for the selected objective
- **Column 3 (Detail):** Tasks for the selected key result

**Persistence:** SwiftData with CloudKit automatic sync

---

## 🌍 Localization

SoloOKRs supports **9 languages** with real-time switching (no restart required):

| Language | Code |
|----------|------|
| English | `en` |
| Simplified Chinese (简体中文) | `zh-Hans` |
| Traditional Chinese (繁體中文) | `zh-Hant` |
| Japanese (日本語) | `ja` |
| Korean (한국어) | `ko` |
| German (Deutsch) | `de` |
| French (Français) | `fr` |
| Spanish (Español) | `es` |
| Portuguese - Brazil (Português) | `pt-BR` |

Change language via **Settings → General → App Language**.

---

## 🚀 Getting Started

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later
- Apple Developer account (for CloudKit sync)

### Build & Run

```bash
# Clone the repository
git clone https://github.com/your-username/SoloOKRs.git
cd SoloOKRs

# Build
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64'

# Or open in Xcode
open src/SoloOKRs/SoloOKRs.xcodeproj
```

### Run Tests

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs test -destination 'platform=macOS,arch=arm64'
```

---

## 🛡 Security

- **API Keys** are stored in the macOS **Keychain** using `kSecUseDataProtectionKeychain`
- **No telemetry** — all data stays on your device and iCloud
- **Local AI** — Ollama and LM Studio support means your OKR data never leaves your machine

---

## 🙏 Acknowledgments

Built with these excellent open-source libraries:

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) — Markdown rendering in SwiftUI
- [Splash](https://github.com/JohnSundell/Splash) — Code syntax highlighting
- [SwiftNIO](https://github.com/apple/swift-nio) — Event-driven networking framework

---

## 📄 License

This project is licensed under the **Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License (CC BY-NC-ND 4.0)**.

### You are free to:

- **Share** — copy and redistribute the material in any medium or format

### Under the following terms:

- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made
- **NonCommercial** — You may **not** use the material for commercial purposes
- **NoDerivatives** — If you remix, transform, or build upon the material, you may **not** distribute the modified material

### ⚠️ Commercial Use is Strictly Prohibited

This includes but is not limited to:
- Selling or distributing the application for profit
- Using the codebase in commercial products or services
- Offering paid services based on this software

For the full license text, see: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

---

<p align="center">
  Made with ❤️ for personal productivity
</p>
