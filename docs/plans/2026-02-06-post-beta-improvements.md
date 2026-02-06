# Post-Beta Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Polish the application based on beta testing feedback, focusing on Review Mode workflow, Objective lifecycle states, and AI integration refinements.

**Architecture:** Refine MVVM pattern in SwiftUI views. Centralize permission logic in `ReviewModeManager`. Enhance `AIService` for Draft->Active analysis.

**Tech Stack:** SwiftUI, SwiftData, Google Gemini API, UserNotifications.

---

### Task 1: Objective List Tabs & Item Appearance

**Description:** Split Objective list into 4 tabs (Draft, Active, Achieved, Archived). Remove status label from rows.

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveListView.swift`
- Test: Manual verification (UI)

**Step 1: Modify ObjectiveListView to use 4 tabs**

```swift
// ObjectiveListView.swift
enum ObjectiveTab: String, CaseIterable {
    case draft = "Draft" // New
    case active = "Active"
    case achieved = "Achieved" // New
    case archived = "Archived"
}

// Update filteredObjectives to switch on all 4 cases
```

**Step 2: Update ObjectiveRowView**

Remove the `status` icon/text from the row. Show only Title and Description.

**Step 3: Verify**
Run app, check 4 tabs appear and filter correctly.

---

### Task 2: Review Mode Button Location

**Description:** Move Review Mode button to bottom left (next to Add Objective). Remove "Hide Sidebar" button.

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/ContentView.swift`

**Step 1: Move Sidebar Controls**

Locate the ToolbarItem(placement: .navigation) or similar for sidebar toggle and remove it.
Add the "Enter Review Mode" button to the bottom of the Sidebar column (safe area inset) or Toolbar.

**Step 2: Verify**
Run app, verify button placement.

---

### Task 3: Review Mode Behavior & Logic

**Description:** When entering Review Mode: Auto-switch to "Active" tab. Show edit icons. Enable editing.

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Services/ReviewModeManager.swift`
- Modify: `src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveListView.swift`

**Step 1: Update ReviewModeManager to trigger tab switch**

Add a publisher or binding that `ObjectiveListView` observes to switch `selectedTab` to `.active` when `enterReviewMode()` is called.

**Step 2: Add Edit Icons in Review Mode**

In `ObjectiveRowView`, conditionally show a `pencil` icon if `ReviewModeManager.shared.isInReviewMode`.

**Step 3: Verify**
Run app, click "Review Mode". Verify tab switches to Active and pencil icons appear.

---

### Task 4: Edit Permission Matrix Enforcement

**Description:** Enforce read-only states for Active/Achieved/Archived unless in Review Mode (for Active).

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Services/ReviewModeManager.swift` (Update `canEditOKR` logic)
- Modify: `src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveDetailView.swift` (Disable editing)
- Modify: `src/SoloOKRs/SoloOKRs/Views/KeyResults/KeyResultDetailView.swift`

**Step 1: Update Permission Logic**

Update `canEditOKR` to match matrix:

- Draft: Always Editable
- Active: Read-only (unless Review Mode)
- Achieved/Archived: Always Read-only

**Step 2: Apply to Views**

Use `.disabled(!canEdit)` on form fields in Detail views.

**Step 3: Verify**
Create Draft (Editable). Move to Active -> check Read-only. Enter Review Mode -> check Editable.

---

### Task 5: New Objective Default Draft

**Description:** Creating a new objective should default to `.draft` and hide the status picker.

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Views/Objectives/AddObjectiveView.swift`

**Step 1: Hide Status Picker**

Remove `Picker("Status", selection: $status)` from `AddObjectiveView`.
Ensure `status` defaults to `.draft`.

**Step 2: Verify**
Add new objective. Verify it appears in Draft tab.

---

### Task 6: Draft Publish Workflow (AI Analysis)

**Description:** In Draft tab, show "Publish" icon. On click -> AI Analysis -> Confirm move to Active.

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveRowView.swift`
- Modify: `src/SoloOKRs/SoloOKRs/Services/AIProvider/AIService.swift`

**Step 1: Add Publish Button**

In `ObjectiveRowView`, if `status == .draft`, show "arrow.up.circle" (Publish).

**Step 2: Implement Publish Action**

Call `AIService.analyzeOKR`. Show alert with "AI Suggestions".
Add "Promote to Active" button in the alert/sheet.

**Step 3: Verify**
Click Publish on a draft. See AI analysis. Click Promote. Verify it moves to Active tab.

---

### Task 7: Task Preview Markdown

**Description:** Show Markdown description in Task preview (TaskDetailView read-only mode).

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Views/Tasks/TaskDetailView.swift`

**Step 1: Use Markdown Rendering**

Ensure the "Read-only" view uses `Text(LocalizedStringKey(description))` or `MarkdownEditorView` in preview mode.

**Step 2: Verify**
Add markdown task description. Switch to view mode. Verify rendering.

---

### Task 8: Settings - AI Provider UI

**Description:** Dedicate settings UI for each provider (Model selection list).

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Services/AIProvider/AIProvider.swift` (Add model list support)
- Modify: `src/SoloOKRs/SoloOKRs/Views/Settings/AIProviderSettingsView.swift`

**Step 1: Add Models to Provider Struct**

Add `availableModels: [String]` to provider config.

**Step 2: Create Settings UI**

For selected provider, show `Picker("Model", selection: $model)`.

**Step 3: Verify**
Go to Settings -> AI. Select Google Gemini. Pick a model (e.g., gemini-1.5-pro).

---

### Task 9: Settings - MCP Toggle Fix

**Description:** Fix "Enable MCP Server" toggle not working.

**Files:**

- Modify: `src/SoloOKRs/SoloOKRs/Views/Settings/MCPSettingsView.swift`
- Modify: `src/SoloOKRs/SoloOKRs/Services/MCPServer/MCPServer.swift`

**Step 1: Debug Toggle**

Check if `MCPServer.shared.isEnabled` is persisted and if `start()/stop()` is called on change.

**Step 2: Fix Logic**

Ensure `onChange(of: isEnabled)` calls `MCPServer.shared.restart()`.

**Step 3: Verify**
Toggle MCP in Settings. Check logs for Server Start/Stop.

---

### Task 10: App Icon (Gemini)

**Description:** Generate and add App Icon.

**Step 1: Generate Icon**
Use `generate_image` tool. "App icon for OKR management app, minimalist, abstract target/arrow, clean gradient blue/purple".

**Step 2: Add to Assets**
Add to `Assets.xcassets`.

**Step 3: Verify**
Run app. Check Dock icon.
