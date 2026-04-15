# Beta 7: Subscription Removal, Data Cleanup Relocation & README

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all subscription/IAP logic, relocate the "Delete all data" feature to the Sync tab, and create an open-source README.

**Architecture:** Clean removal of the self-contained subscription subsystem (3 files + 1 tab reference), then adding the delete-data functionality into the existing SyncSettingsView. Finally, create a polished README.md at the project root for GitHub open-source release.

**Tech Stack:** Swift, SwiftUI, SwiftData, Markdown

---

## Proposed Changes

### Component 1: Subscription Removal

#### [DELETE] [SubscriptionSettingsView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Settings/SubscriptionSettingsView.swift)
The entire subscription tab UI, including `ProductRow`. Currently contains the "Delete All App Data" feature which will be moved first.

#### [DELETE] [SubscriptionManager.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Services/Subscription/SubscriptionManager.swift)
StoreKit 2 integration singleton — only referenced by `SubscriptionSettingsView`. No other views depend on it.

#### [DELETE] [SubscriptionStatus.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/Enums/SubscriptionStatus.swift)
Enum only used by `SubscriptionManager`.

#### [MODIFY] [SettingsView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Settings/SettingsView.swift)
Remove the `SubscriptionSettingsView()` tab item (lines 43–47).

---

### Component 2: Move "Delete All App Data" to Sync

#### [MODIFY] [SyncSettingsView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Settings/SyncSettingsView.swift)
Add the "Danger Zone" section with the delete data confirmation dialog. Requires `@Environment(\.modelContext)` and SwiftData imports.

---

### Component 3: README.md

#### [NEW] [README.md](file:///Users/kane/Code/SoloOKRs/README.md)
Comprehensive project README for GitHub open-source release, covering features, architecture, MCP integration, AI assistance, and a CC BY-NC-ND 4.0 non-commercial license.

---

## Tasks

### Task 1: Move "Delete All App Data" to SyncSettingsView

**Files:**
- Modify: `src/SoloOKRs/SoloOKRs/Views/Settings/SyncSettingsView.swift`

- [ ] **Step 1: Update SyncSettingsView with delete data functionality**

Replace the entire file content with:

```swift
// SyncSettingsView.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import SwiftUI
import SwiftData

struct SyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearConfirmation = false
    @State private var showingError = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("iCloud Sync") {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                    Text("Synced")
                }

                Text("Changes sync automatically via iCloud")
                    .foregroundStyle(.secondary)
            }

            Section("Actions") {
                Button("Sync Now") {
                    // Manual sync trigger
                }
            }

            // Danger Zone
            Section("Danger Zone") {
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete All App Data")
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Sync")
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onChange(of: errorMessage) { _, newValue in
            showingError = newValue != nil
        }
        .confirmationDialog("Clear All Data?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Delete All Objectives, Key Results & Tasks", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your OKR data. This action cannot be undone.")
        }
    }

    private func clearAllData() {
        DispatchQueue.main.async {
            do {
                try modelContext.delete(model: Objective.self)
                try modelContext.save()
            } catch {
                errorMessage = "Failed to clear data: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    SyncSettingsView()
}
```

- [ ] **Step 2: Verify build**

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64' > /tmp/build_log.txt 2>&1 || grep -A 5 -B 5 "error:" /tmp/build_log.txt
```

---

### Task 2: Remove Subscription Tab from SettingsView

**Files:**
- Modify: `src/SoloOKRs/SoloOKRs/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Remove the SubscriptionSettingsView tab**

In `SettingsView.swift`, remove lines 43–47 (the `SubscriptionSettingsView()` tab item):

```diff
             SyncSettingsView()
                 .tabItem {
                     Label("Sync", systemImage: "icloud")
                 }
                 .tag("sync")
-
-            SubscriptionSettingsView()
-                .tabItem {
-                    Label("Subscription", systemImage: "creditcard")
-                }
-                .tag("subscription")
         }
```

---

### Task 3: Delete Subscription Files

**Files:**
- Delete: `src/SoloOKRs/SoloOKRs/Views/Settings/SubscriptionSettingsView.swift`
- Delete: `src/SoloOKRs/SoloOKRs/Services/Subscription/SubscriptionManager.swift`
- Delete: `src/SoloOKRs/SoloOKRs/Models/Enums/SubscriptionStatus.swift`

- [ ] **Step 1: Delete the three subscription files**

```bash
rm src/SoloOKRs/SoloOKRs/Views/Settings/SubscriptionSettingsView.swift
rm src/SoloOKRs/SoloOKRs/Services/Subscription/SubscriptionManager.swift
rm src/SoloOKRs/SoloOKRs/Models/Enums/SubscriptionStatus.swift
rmdir src/SoloOKRs/SoloOKRs/Services/Subscription
```

- [ ] **Step 2: Full build verification**

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64' > /tmp/build_log.txt 2>&1 || grep -A 5 -B 5 "error:" /tmp/build_log.txt
```

Expected: Build succeeds with no errors (subscription code was fully self-contained).

---

### Task 4: Create README.md

**Files:**
- Create: `README.md` (project root)

- [ ] **Step 1: Write README.md**

The README should cover:
1. **Project title & tagline** — SoloOKRs, personal OKR management for macOS
2. **Screenshots placeholder** — space for app screenshots
3. **Features overview** — OKR hierarchy, AI assistance, MCP server, review mode, i18n
4. **Special features deep dive** — AI integration (5 providers), MCP protocol (HTTP + UDS), thinking blocks, review/retrospective workflow
5. **Tech stack** — Swift, SwiftUI, SwiftData, CloudKit, SwiftNIO
6. **Getting started** — build & run instructions
7. **Architecture** — 3-column NavigationSplitView, service layer overview
8. **Localization** — 9 supported languages
9. **License** — CC BY-NC-ND 4.0 (non-commercial, no derivatives without permission)

> [!IMPORTANT]
> The license uses **Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)** which explicitly prohibits commercial use. This is NOT the typical MIT/Apache for open-source code — it's a deliberate choice per user requirements.

---

## Verification Plan

### Automated Tests
```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64' > /tmp/build_log.txt 2>&1 || grep -A 5 -B 5 "error:" /tmp/build_log.txt
```

### Manual Verification
- Confirm Settings window shows 5 tabs: General, AI, Prompts, MCP, Sync (no Subscription)
- Confirm "Delete All App Data" button appears in the Sync tab under "Danger Zone"
- Confirm the delete confirmation dialog works correctly
- Review README.md renders correctly on GitHub

## Open Questions

> [!IMPORTANT]
> **License choice:** I'm proposing **CC BY-NC-ND 4.0** which prohibits commercial use AND derivative works. If you want to allow others to fork and modify (but still prohibit commercial use), **CC BY-NC-SA 4.0** would be more appropriate for an open-source project. Which do you prefer?
>
> - **CC BY-NC-ND 4.0** — No commercial use, no derivative works (strictest)
> - **CC BY-NC-SA 4.0** — No commercial use, derivatives must use same license (allows forks)
> - **AGPL-3.0 with Commons Clause** — Strong copyleft + commercial use restriction
