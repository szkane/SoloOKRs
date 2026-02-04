# SOLO OKRs - App Design Document

> **Date:** 2026-02-03  
> **Status:** Draft - Pending User Approval

---

## Executive Summary

SOLO OKRs is a native macOS 26 app for personal OKR (Objectives and Key Results) management. It features a 3-column interface, AI-powered suggestions, MCP integration for AI agent access, and iCloud sync for cross-device availability.

---

## Brainstorming Q&A Summary

| #   | Question            | Decision                                                                              |
| --- | ------------------- | ------------------------------------------------------------------------------------- |
| 1   | Target Platform     | **macOS 26+ only** - Full Liquid Glass, latest SwiftUI APIs                           |
| 2   | Data Storage        | **SwiftData + CloudKit** - Modern persistence with automatic iCloud sync              |
| 3   | MCP Architecture    | **Embedded MCP server** - App runs local server on localhost for AI agents            |
| 4   | AI Features         | **All features** - Quality analysis, smart suggestions, template generation           |
| 5   | AI Provider         | **User-configurable** - Support Gemini, OpenAI, Anthropic, Ollama, LM Studio, custom  |
| 6   | UI Layout           | **Master-Detail-Detail with NavigationSplitView** - Native 3-column macOS layout      |
| 7   | Key Result Tracking | **Flexible** - User chooses type per KR (percentage, numeric, milestone, binary)      |
| 8   | Task Structure      | **Rich tasks** - Title, Markdown description, due date, priority                      |
| 9   | Objective Status    | **Extended** - Draft, Active, Review, Achieved, Archived                              |
| 10  | Monetization        | **IAP with Trial** - Free trial (3 objectives or 7-14 days), then purchase required   |
| 11  | Multilingual        | **Auto-detect + Custom** - Follow system language, allow user override in Settings    |
| 12  | Edit Permissions    | **State-based** - OKRs editable only in Draft/Review; read-only when Active           |
| 13  | Review Mode         | **Configurable** - Weekly/bi-weekly reminders, manual entry; OKR edits only in Review |
| 14  | Deletion Policy     | **Archive-only** - OKRs cannot be deleted, only archived; Tasks can be deleted        |

---

## 1. Platform & Technology Stack

### Target

- **macOS 26+ (Tahoe)** only
- Fully embraces Liquid Glass design language
- Uses latest SwiftUI APIs without backward compatibility constraints

### Core Technologies

| Layer          | Technology                        | Rationale                                   |
| -------------- | --------------------------------- | ------------------------------------------- |
| UI Framework   | SwiftUI                           | Native macOS, Liquid Glass support          |
| Persistence    | SwiftData                         | Modern, Swift-native ORM                    |
| Cloud Sync     | CloudKit                          | Automatic via SwiftData, iCloud integration |
| MCP Server     | Swift NIO / Vapor                 | Lightweight embedded HTTP server            |
| AI Integration | Custom Protocol                   | Pluggable provider architecture             |
| Markdown       | swift-markdown + AttributedString | Native rendering                            |
| Networking     | URLSession                        | AI API calls                                |

### Project Structure

```
SoloOKRs/
├── SoloOKRsApp.swift              # App entry point, lifecycle
├── Models/
│   ├── Objective.swift            # SwiftData model
│   ├── KeyResult.swift            # SwiftData model
│   ├── Task.swift                 # SwiftData model
│   └── Enums/
│       ├── KeyResultType.swift    # Percentage, Numeric, Milestone, Binary
│       ├── Priority.swift         # Low, Medium, High, Urgent
│       ├── OKRStatus.swift        # Draft, Active, Review, Achieved, Archived
│       └── SubscriptionStatus.swift # Trial, Subscribed, Expired
├── Views/
│   ├── ContentView.swift          # Main NavigationSplitView
│   ├── Objectives/
│   │   ├── ObjectiveListView.swift
│   │   ├── ObjectiveRowView.swift
│   │   └── ObjectiveDetailView.swift
│   ├── KeyResults/
│   │   ├── KeyResultListView.swift
│   │   ├── KeyResultRowView.swift
│   │   └── KeyResultDetailView.swift
│   ├── Tasks/
│   │   ├── TaskListView.swift
│   │   ├── TaskRowView.swift
│   │   └── TaskDetailView.swift
│   ├── AI/
│   │   ├── AIAssistantView.swift
│   │   └── AISuggestionsView.swift
│   ├── Settings/                     # Multi-tab Settings window (like Mail.app)
│   │   ├── SettingsView.swift         # Main settings container
│   │   ├── GeneralSettingsView.swift  # General preferences
│   │   ├── AIProviderSettingsView.swift
│   │   ├── MCPSettingsView.swift      # MCP server settings
│   │   ├── SyncSettingsView.swift     # iCloud sync settings
│   │   └── SubscriptionSettingsView.swift  # IAP & subscription
│   └── Components/
│       ├── ProgressIndicator.swift
│       ├── MarkdownEditor.swift
│       └── MarkdownPreview.swift
├── Services/
│   ├── MCPServer/
│   │   ├── MCPServer.swift        # HTTP server lifecycle
│   │   ├── MCPRouter.swift        # Route handlers
│   │   └── MCPTools.swift         # Tool implementations
│   ├── AIProvider/
│   │   ├── AIProvider.swift       # Protocol definition
│   │   ├── GeminiProvider.swift
│   │   ├── OpenAIProvider.swift
│   │   ├── AnthropicProvider.swift
│   │   ├── OllamaProvider.swift
│   │   ├── LMStudioProvider.swift
│   │   └── AIService.swift        # Provider manager
│   └── Subscription/
│       ├── SubscriptionManager.swift  # StoreKit 2 integration
│       ├── TrialManager.swift         # Trial period tracking
│       └── PaywallView.swift          # Purchase UI
├── Utilities/
│   ├── MarkdownParser.swift
│   └── DateFormatters.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### macOS 26 Features Used

- **Liquid Glass** materials on sidebars, toolbars, and sheets
- **NavigationSplitView** with 3-column layout
- **SwiftData** with CloudKit sync
- **Native window management** - Full-screen, split-view support
- **.inspector** modifier for detail panels

---

## 2. Data Model

### Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   Objective     │       │   KeyResult     │       │     Task        │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id: UUID        │──1:N──│ id: UUID        │──1:N──│ id: UUID        │
│ title: String   │       │ title: String   │       │ title: String   │
│ description     │       │ type: KRType    │       │ description: MD │
│ startDate       │       │ targetValue     │       │ dueDate         │
│ endDate         │       │ currentValue    │       │ priority        │
│ status          │       │ milestones[]    │       │ isCompleted     │
│ order: Int      │       │ order: Int      │       │ order: Int      │
│ createdAt       │       │ createdAt       │       │ createdAt       │
│ updatedAt       │       │ objective ←     │       │ keyResult ←     │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

### SwiftData Models

#### Objective

```swift
@Model
class Objective {
    @Attribute(.unique) var id: UUID
    var title: String
    var objectiveDescription: String
    var startDate: Date
    var endDate: Date
    var status: OKRStatus  // .draft, .active, .review, .achieved, .archived
    var lastReviewedAt: Date?  // Track when last reviewed
    var archivedAt: Date?      // Track when archived
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \KeyResult.objective)
    var keyResults: [KeyResult]

    /// OKRs are only editable in Draft or Review states
    var isEditable: Bool {
        status == .draft || status == .review
    }
}
```

#### OKRStatus Enum

```swift
enum OKRStatus: String, Codable {
    case draft      // Not yet started
    case active     // Currently being worked on
    case review     // Pending review (important for regular OKR check-ins)
    case achieved   // Successfully completed
    case archived   // No longer relevant, kept for history
}
```

#### KeyResult

```swift
@Model
class KeyResult {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: KeyResultType  // .percentage, .numeric, .milestone, .binary
    var targetValue: Double?
    var currentValue: Double?
    var milestones: [String]  // For milestone type
    var completedMilestones: [Bool]
    var isCompleted: Bool  // For binary type
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    var objective: Objective?

    @Relationship(deleteRule: .cascade, inverse: \Task.keyResult)
    var tasks: [Task]

    var progress: Double { /* calculated based on type */ }
}
```

#### Task

```swift
@Model
class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String  // Markdown content
    var dueDate: Date?
    var priority: Priority  // .low, .medium, .high, .urgent
    var isCompleted: Bool
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    var keyResult: KeyResult?
}
```

### Key Result Types

| Type           | Fields Used                             | Progress Calculation            |
| -------------- | --------------------------------------- | ------------------------------- |
| **Percentage** | `currentValue` (0-100)                  | `currentValue / 100`            |
| **Numeric**    | `currentValue`, `targetValue`           | `currentValue / targetValue`    |
| **Milestone**  | `milestones[]`, `completedMilestones[]` | `completed.count / total.count` |
| **Binary**     | `isCompleted`                           | `isCompleted ? 1.0 : 0.0`       |

### Task Priorities

| Priority | Display   | Sort Order |
| -------- | --------- | ---------- |
| Low      | 🟢 Low    | 4          |
| Medium   | 🟡 Medium | 3          |
| High     | 🟠 High   | 2          |
| Urgent   | 🔴 Urgent | 1          |

---

## 3. UI Architecture

### Main Window Layout

```
┌──────────────────────────────────────────────────────────────────────────┐
│  🎯 SOLO OKRs                                              ─  □  ✕      │
├────────────────┬─────────────────────┬───────────────────────────────────┤
│                │                     │                                   │
│  OBJECTIVES    │  KEY RESULTS        │  TASKS                           │
│  ─────────────│  ──────────────────  │  ────────────────────────────────│
│                │                     │                                   │
│  ▶ Q1 2026     │  📊 Revenue +20%    │  ☐ Draft pricing proposal        │
│    ├─ Growth   │     ████████░░ 80%  │     Due: Feb 15 | High           │
│    └─ Quality  │                     │                                   │
│                │  📈 50 New Customers │  ☐ Launch marketing campaign     │
│  ▶ Q2 2026     │     35/50 (70%)     │     Due: Feb 20 | Medium         │
│    ├─ Launch   │                     │                                   │
│    └─ Hire     │  ✓ Onboard 3 Devs   │  ☑ Post job listings             │
│                │     ██████████ Done │     Completed ✓                  │
│                │                     │                                   │
│  ┌───────────┐ │                     │  ┌─────────────────────────────┐ │
│  │  + New    │ │                     │  │  + Add Task    🤖 AI Help   │ │
│  └───────────┘ │                     │  └─────────────────────────────┘ │
├────────────────┴─────────────────────┴───────────────────────────────────┤
│  ⚙️ Settings  │  🤖 AI: Claude (Ready)  │  ☁️ iCloud: Synced           │
└──────────────────────────────────────────────────────────────────────────┘
```

### Column Behavior

| Column          | Content                               | Selection Effect           |
| --------------- | ------------------------------------- | -------------------------- |
| **Objectives**  | All objectives grouped by time period | Filters Key Results column |
| **Key Results** | KRs for selected objective            | Filters Tasks column       |
| **Tasks**       | Tasks for selected Key Result         | Shows task detail/editor   |

### Liquid Glass Implementation

- **Sidebar (Column 1):** `.glassBackgroundEffect()` with system material
- **Middle Column:** Standard content background
- **Detail Column:** Subtle glass effect on headers
- **Toolbar:** Liquid Glass toolbar style
- **Sheets/Modals:** Glass background with blur

### Key UI Components

| Component           | Description                                 |
| ------------------- | ------------------------------------------- |
| `ProgressIndicator` | Visual progress bar adapting to KR type     |
| `MarkdownEditor`    | Two-pane editor with live preview toggle    |
| `MarkdownPreview`   | Renders Markdown as styled AttributedString |
| `AIAssistantButton` | Floating action button for AI features      |
| `PriorityBadge`     | Colored tag showing task priority           |

---

## 4. MCP Server Integration

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  SOLO OKRs App                                              │
│  ┌─────────────────────┐    ┌─────────────────────────┐    │
│  │  SwiftUI Views      │◄──►│  SwiftData Store        │    │
│  └─────────────────────┘    └───────────▲─────────────┘    │
│                                         │                   │
│  ┌─────────────────────────────────────┐│                   │
│  │  Embedded MCP Server (localhost)    ││                   │
│  │  ┌─────────┐  ┌─────────────────┐  ││                   │
│  │  │ HTTP    │  │  MCP Tools      │──┘│                   │
│  │  │ :5100   │──│  (JSON-RPC)     │    │                   │
│  │  └─────────┘  └─────────────────┘    │                   │
│  └─────────────────────────────────────┘                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
          ┌─────────────▼─────────────┐
          │  AI Agent (Claude Desktop) │
          │  Connects to localhost:5100│
          └───────────────────────────┘
```

### MCP Server Lifecycle

1. **Starts** when app launches (configurable in Settings)
2. **Listens** on `localhost:5100` (port configurable)
3. **Stops** when app quits
4. **Status** shown in app status bar

### MCP Tools

| Tool                | Parameters                                                      | Description                                 |
| ------------------- | --------------------------------------------------------------- | ------------------------------------------- |
| `list_objectives`   | `status?`, `startDate?`, `endDate?`                             | List objectives with optional filters       |
| `get_objective`     | `id`                                                            | Get single objective with all KRs and tasks |
| `create_objective`  | `title`, `description`, `startDate`, `endDate`                  | Create new objective                        |
| `update_objective`  | `id`, `title?`, `description?`, `status?`                       | Update objective fields                     |
| `delete_objective`  | `id`                                                            | Delete objective and cascade                |
| `list_key_results`  | `objectiveId?`, `type?`                                         | List key results                            |
| `create_key_result` | `objectiveId`, `title`, `type`, `targetValue?`                  | Create new KR                               |
| `update_progress`   | `id`, `currentValue?`, `milestoneIndex?`, `isCompleted?`        | Update KR progress                          |
| `list_tasks`        | `keyResultId?`, `priority?`, `isCompleted?`, `dueBefore?`       | List tasks with filters                     |
| `create_task`       | `keyResultId`, `title`, `description?`, `dueDate?`, `priority?` | Create new task                             |
| `update_task`       | `id`, `title?`, `description?`, `dueDate?`, `priority?`         | Update task fields                          |
| `complete_task`     | `id`, `isCompleted`                                             | Toggle task completion                      |
| `get_summary`       | `objectiveId?`                                                  | Get progress summary and statistics         |

### MCP Configuration (for AI agents)

```json
{
  "mcpServers": {
    "solo-okrs": {
      "url": "http://localhost:5100",
      "transport": "http"
    }
  }
}
```

---

## 5. AI Features

### Provider Architecture

```swift
protocol AIProvider {
    var name: String { get }
    var isConfigured: Bool { get }

    func complete(prompt: String, systemPrompt: String?) async throws -> String
    func streamComplete(prompt: String, systemPrompt: String?) -> AsyncThrowingStream<String, Error>
}
```

### Supported Providers

| Provider      | Models                    | Configuration                           |
| ------------- | ------------------------- | --------------------------------------- |
| **Gemini**    | Any Gemini model          | API Key                                 |
| **OpenAI**    | Any OpenAI model          | API Key                                 |
| **Anthropic** | Any Anthropic model       | API Key                                 |
| **Ollama**    | Any local model           | Endpoint URL (default: localhost:11434) |
| **LM Studio** | Any local model           | Endpoint URL (default: localhost:1234)  |
| **Custom**    | Any OpenAI-compatible API | Endpoint URL + API Key                  |

### AI Features

| Feature                     | Trigger                   | Prompt Strategy                                        |
| --------------------------- | ------------------------- | ------------------------------------------------------ |
| **OKR Quality Analysis**    | "🤖 Analyze" on objective | Evaluate against SMART criteria, suggest improvements  |
| **KR Suggestions**          | After creating objective  | Based on objective, suggest 3-5 measurable key results |
| **Task Suggestions**        | After creating KR         | Based on KR, suggest actionable tasks to achieve it    |
| **Template Generation**     | "🤖 Generate OKR" button  | User describes goal, AI generates full OKR structure   |
| **Description Enhancement** | In Markdown editor        | Improve clarity and structure of descriptions          |

### Settings UI

- Dropdown to select default AI provider
- API key input fields (stored in Keychain)
- Test connection button
- Toggle to enable/disable AI features

---

## 6. CloudKit Sync

### Automatic Sync via SwiftData

SwiftData with CloudKit enabled provides:

- **Automatic sync** of all model changes
- **Conflict resolution** (last-write-wins by default)
- **Offline support** with local cache
- **Cross-device** sync via iCloud account

### Configuration

```swift
@main
struct SoloOKRsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Objective.self, KeyResult.self, Task.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // Enables CloudKit sync
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

### Sync Status Indicator

- **Status bar** shows sync state: Syncing, Synced, Offline, Error
- **Pull-to-refresh** triggers manual sync check
- **Conflict indicator** on items with sync conflicts (rare)

---

## 7. In-App Purchases & Trial

### Monetization Strategy

The app uses a **freemium model** with a generous trial to let users experience the full product before purchasing.

### Trial Limitations

| Trial Type          | Limitation               | Rationale                         |
| ------------------- | ------------------------ | --------------------------------- |
| **Objective Limit** | Max 3 objectives         | Enough to understand OKR workflow |
| **Time-based**      | 7-14 days (configurable) | Full feature access during trial  |

> **Note:** Choose ONE trial type. Recommend **objective limit** as it's value-based rather than time-pressure.

### Subscription Tiers

| Tier                   | Price      | Features                               |
| ---------------------- | ---------- | -------------------------------------- |
| **Free (Trial)**       | $0         | 3 objectives, all features             |
| **Pro (One-time)**     | $X.XX      | Unlimited objectives, lifetime access  |
| **Pro (Subscription)** | $X.XX/year | Unlimited objectives, priority support |

> **Decision needed:** One-time purchase vs. subscription model

### StoreKit 2 Implementation

```swift
// SubscriptionManager.swift
@Observable
class SubscriptionManager {
    var subscriptionStatus: SubscriptionStatus = .trial
    var objectivesCreated: Int = 0

    var canCreateObjective: Bool {
        subscriptionStatus == .subscribed || objectivesCreated < 3
    }

    func purchase(_ product: Product) async throws {
        // StoreKit 2 purchase flow
    }

    func restorePurchases() async throws {
        // Restore previous purchases
    }
}

enum SubscriptionStatus: String, Codable {
    case trial       // Within trial limits
    case subscribed  // Purchased/subscribed
    case expired     // Subscription lapsed (if using subscription model)
}
```

### Paywall Triggers

- When user tries to create 4th objective (if using objective limit)
- After trial period expires (if using time-based)
- From Settings → Subscription tab (anytime)

### Paywall UI

- Clear value proposition
- Show what's included
- Restore purchases button
- Privacy policy and terms links

---

## 8. Settings (Preferences Window)

### Architecture

Multi-tab Settings window following macOS conventions (similar to Mail.app, Xcode, etc.)

```swift
@main
struct SoloOKRsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            SettingsView()
        }
    }
}
```

### Settings Tabs

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ⚙️ Settings                                              ─  □  ✕      │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────────┐      │
│  │ General │ │   AI    │ │   MCP   │ │  Sync   │ │ Subscription │      │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └──────────────┘      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  [Content changes based on selected tab]                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tab Details

#### General Settings

| Setting          | Description                     |
| ---------------- | ------------------------------- |
| Default view     | Which column to focus on launch |
| Date format      | Date display preferences        |
| Theme            | Follow system / Light / Dark    |
| Launch at login  | Start app on macOS boot         |
| Show in menu bar | Optional menu bar icon          |

#### AI Provider Settings

| Setting            | Description                                                    |
| ------------------ | -------------------------------------------------------------- |
| Default provider   | Dropdown: Gemini, OpenAI, Anthropic, Ollama, LM Studio, Custom |
| API Keys           | Secure input fields (stored in Keychain)                       |
| Model selection    | Per-provider model choice                                      |
| Endpoint URLs      | For Ollama, LM Studio, Custom                                  |
| Test connection    | Verify provider is working                                     |
| Enable AI features | Master toggle                                                  |

#### MCP Server Settings

| Setting            | Description                 |
| ------------------ | --------------------------- |
| Enable MCP server  | Toggle server on/off        |
| Port               | Default: 5100, customizable |
| Auto-start         | Start server with app       |
| Show in status bar | Display server status       |

#### Sync Settings

| Setting             | Description                  |
| ------------------- | ---------------------------- |
| iCloud sync         | Enable/disable CloudKit sync |
| Sync status         | Current sync state display   |
| Sync now            | Manual sync trigger          |
| Conflict resolution | Last-write-wins or manual    |

#### Subscription Settings

| Setting             | Description                      |
| ------------------- | -------------------------------- |
| Current plan        | Show current subscription status |
| Objectives used     | X of 3 (if on trial)             |
| Upgrade             | Open paywall                     |
| Restore purchases   | StoreKit restore                 |
| Manage subscription | Link to App Store subscriptions  |

### Implementation

```swift
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            AIProviderSettingsView()
                .tabItem { Label("AI", systemImage: "brain") }

            MCPSettingsView()
                .tabItem { Label("MCP", systemImage: "network") }

            SyncSettingsView()
                .tabItem { Label("Sync", systemImage: "icloud") }

            SubscriptionSettingsView()
                .tabItem { Label("Subscription", systemImage: "creditcard") }
        }
        .frame(width: 500, height: 400)
    }
}
```

---

## 9. Multilingual Support (Localization)

### Strategy

The app automatically adapts to the system language while allowing users to set a custom language preference.

### Supported Languages (Initial)

| Language            | Code    | Priority |
| ------------------- | ------- | -------- |
| English             | en      | Primary  |
| Simplified Chinese  | zh-Hans | High     |
| Traditional Chinese | zh-Hant | High     |
| Japanese            | ja      | Medium   |
| Korean              | ko      | Medium   |
| German              | de      | Medium   |
| French              | fr      | Medium   |
| Spanish             | es      | Medium   |

> **Note:** Start with English + Chinese, add others based on user demand.

### Implementation

```swift
// Language preference stored in UserDefaults
@AppStorage("preferredLanguage") var preferredLanguage: String = ""  // Empty = system default

// Get current language
var currentLanguage: String {
    preferredLanguage.isEmpty ? Locale.current.language.languageCode?.identifier ?? "en" : preferredLanguage
}
```

### Localization Files

```
SoloOKRs/Resources/
├── Localizable.xcstrings          # Main strings catalog (Xcode 15+ format)
├── en.lproj/
│   └── InfoPlist.strings
├── zh-Hans.lproj/
│   └── InfoPlist.strings
└── zh-Hant.lproj/
    └── InfoPlist.strings
```

### String Catalogs

Using modern `.xcstrings` format for:

- UI labels and buttons
- Error messages
- Status descriptions
- OKR status names
- Priority names

### Settings UI

```swift
// In GeneralSettingsView
Section("Language") {
    Picker("App Language", selection: $preferredLanguage) {
        Text("System Default").tag("")
        Divider()
        Text("English").tag("en")
        Text("简体中文").tag("zh-Hans")
        Text("繁體中文").tag("zh-Hant")
        // ... other languages
    }
}
```

---

## 10. Edit Permissions & Review Mode

### Core Principle

> **OKRs should be stable once committed.** Edits are only allowed in specific states to maintain integrity and encourage thoughtful goal-setting.

### Edit Permission Matrix

| Item            | Draft     | Active       | Review    | Achieved     | Archived     |
| --------------- | --------- | ------------ | --------- | ------------ | ------------ |
| **Objective**   | ✅ Edit   | ❌ Read-only | ✅ Edit   | ❌ Read-only | ❌ Read-only |
| **Key Result**  | ✅ Edit   | ❌ Read-only | ✅ Edit   | ❌ Read-only | ❌ Read-only |
| **KR Progress** | ✅ Update | ✅ Update    | ✅ Update | ❌ Read-only | ❌ Read-only |
| **Task**        | ✅ Full   | ✅ Full      | ✅ Full   | ✅ Full      | ❌ Read-only |

### State Transitions

```
┌─────────┐    Publish    ┌─────────┐
│  Draft  │──────────────▶│ Active  │
└─────────┘               └────┬────┘
                               │
                    ┌──────────┼──────────┐
                    │ Enter    │          │ Complete
                    │ Review   ▼          ▼
               ┌────┴────┐         ┌──────────┐
               │ Review  │         │ Achieved │
               └────┬────┘         └────┬─────┘
                    │                   │
                    │ Exit Review       │ Archive
                    ▼                   ▼
               ┌─────────┐        ┌──────────┐
               │ Active  │        │ Archived │
               └─────────┘        └──────────┘
                    │
                    │ Archive (give up)
                    ▼
               ┌──────────┐
               │ Archived │
               └──────────┘
```

### Review Mode

#### Purpose

- Allows periodic review and adjustment of OKRs
- Encourages regular reflection on goals
- Only state where Active OKRs can be modified

#### Entering Review Mode

1. **Manual Entry** - User clicks "Enter Review Mode" button
2. **Scheduled Reminder** - App notifies user when review is due

#### Review Mode Behavior

- All Active and Review status OKRs become editable
- Visual indicator shows "Review Mode Active"
- User must explicitly "Exit Review" to return to normal state
- Unsaved changes prompt confirmation

### Review Schedule Settings

```swift
struct ReviewSettings {
    var isEnabled: Bool = true
    var frequency: ReviewFrequency = .weekly
    var dayOfWeek: Int = 1  // 1 = Monday, 7 = Sunday
    var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!
}

enum ReviewFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
}
```

### Settings UI for Review

```swift
// In GeneralSettingsView or new ReviewSettingsView
Section("Review Schedule") {
    Toggle("Enable Review Reminders", isOn: $reviewSettings.isEnabled)

    if reviewSettings.isEnabled {
        Picker("Frequency", selection: $reviewSettings.frequency) {
            ForEach(ReviewFrequency.allCases, id: \.self) { freq in
                Text(freq.rawValue).tag(freq)
            }
        }

        Picker("Day", selection: $reviewSettings.dayOfWeek) {
            Text("Monday").tag(1)
            Text("Tuesday").tag(2)
            // ... etc
            Text("Sunday").tag(7)
        }

        DatePicker("Time", selection: $reviewSettings.reminderTime, displayedComponents: .hourAndMinute)
    }
}

Section("Review Mode") {
    if isInReviewMode {
        Button("Exit Review Mode") {
            exitReviewMode()
        }
        .foregroundStyle(.orange)
    } else {
        Button("Enter Review Mode") {
            enterReviewMode()
        }
    }
}
```

### UI Indicators

```swift
// In ContentView toolbar
if isInReviewMode {
    Label("Review Mode", systemImage: "pencil.circle.fill")
        .foregroundStyle(.orange)
        .help("OKRs are editable. Click to exit Review Mode.")
}
```

---

## 11. Archiving Policy (No Deletion for OKRs)

### Core Principle

> **OKRs are never deleted, only archived.** This preserves history for reflection and learning from past goals.

### Rules

| Item           | Can Delete? | Archive Instead?                 |
| -------------- | ----------- | -------------------------------- |
| **Objective**  | ❌ No       | ✅ Yes                           |
| **Key Result** | ❌ No       | ✅ Yes (archives with Objective) |
| **Task**       | ✅ Yes      | N/A                              |

### Archive Behavior

1. **Archiving an Objective**
   - Sets status to `.archived`
   - All child Key Results also become read-only
   - All child Tasks become read-only
   - Removed from main view, appears in "Archived" tab

2. **Unarchiving**
   - Returns Objective to `.draft` status (not `.active`)
   - User must re-publish to make it Active again

### UI Changes

#### Main Window with Archive Tab

```
┌──────────────────────────────────────────────────────────────────────────┐
│  🎯 SOLO OKRs                                              ─  □  ✕      │
├────────────────┬─────────────────────┬───────────────────────────────────┤
│  ┌───────────┐ │                     │                                   │
│  │  Active   │ │  KEY RESULTS        │  TASKS                           │
│  └───────────┘ │                     │                                   │
│  ┌───────────┐ │                     │                                   │
│  │ Archived  │ │                     │                                   │
│  └───────────┘ │                     │                                   │
│                │                     │                                   │
│  OBJECTIVES    │                     │                                   │
│  ─────────────│                     │                                   │
│  ▶ Q1 2026     │                     │                                   │
│    ├─ Growth   │                     │                                   │
│    └─ Quality  │                     │                                   │
│                │                     │                                   │
└────────────────┴─────────────────────┴───────────────────────────────────┘
```

#### Context Menu

```swift
// ObjectiveRowView context menu
.contextMenu {
    if objective.status == .archived {
        Button("Unarchive") {
            unarchiveObjective(objective)
        }
    } else {
        // No delete option - only Archive
        Button("Archive", role: .destructive) {
            archiveObjective(objective)
        }
    }
}
```

#### Archive Confirmation

```swift
.confirmationDialog(
    "Archive Objective?",
    isPresented: $showArchiveConfirmation
) {
    Button("Archive", role: .destructive) {
        archiveObjective(selectedObjective)
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This objective and its key results will be moved to the archive. You can view them in the Archived tab.")
}
```

### Data Model Update

Add to `Objective` model:

```swift
var archivedAt: Date?  // Track when archived
```

### Filtering

```swift
// Active objectives (main view)
@Query(filter: #Predicate<Objective> { $0.status != .archived })
private var activeObjectives: [Objective]

// Archived objectives (archive tab)
@Query(filter: #Predicate<Objective> { $0.status == .archived })
private var archivedObjectives: [Objective]
```

---

## 12. Future Considerations

> **Note:** These are documented for future iterations, not part of initial implementation.

- **iOS/iPadOS version** - Share codebase via SwiftUI
- **Widgets** - Show OKR progress on Desktop/Lock Screen
- **Shortcuts integration** - Siri and Shortcuts app support
- **Export/Import** - JSON, CSV, PDF export of OKRs
- **Notifications** - Due date reminders for tasks

---

## Appendix: Open Questions for Future Discussion

1. **UI Polish:** Specific Liquid Glass effects and animations
2. **Onboarding:** First-run experience and tutorial
3. **Keyboard shortcuts:** Power user navigation
4. **Pricing:** Final pricing decision (one-time vs. subscription, price points)
5. **Trial type:** Objective limit (3) vs. time-based (7-14 days)
6. **Dark/Light mode:** Follow system vs. app-specific toggle
