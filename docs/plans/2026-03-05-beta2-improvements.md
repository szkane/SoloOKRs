# Beta 2 Improvement Plan

Two-phase improvement: (1) AI function refactoring — extract all prompts into customizable Settings, improve Objective analyze UI, and optimize Key Result creation; (2) Review mode redesign — replace global toggle with per-Objective review records with structured data (KR progress, status, blockers, next steps).

---

## Phase 1: AI Function Refactoring

### 1.1 Settings → Prompt Management Tab

> [!IMPORTANT]
> New "Prompts" tab placed **right of the AI tab** in Settings. Each prompt is editable via the existing `MarkdownEditorView` (edit/preview toggle). Prompts are stored in `UserDefaults` per language; output language instruction is auto-injected from the app's current locale.

#### All Prompts to Extract (3 total)

| ID            | Name                | Current Location                                         | Usage                                   |
| ------------- | ------------------- | -------------------------------------------------------- | --------------------------------------- |
| `analyzeOKR`  | Analyze OKR         | `AIService.swift` L254-263, L375-384, L520-529, L597-606 | Analyze Objective quality, KR alignment |
| `suggestKR`   | Suggest Key Results | `AIService.swift` L288-294, L389-396, L533-540, L611-617 | Suggest KRs for an Objective            |
| `suggestTask` | Suggest Tasks       | `AIService.swift` L319-325, L402-408, L545-551, L622-628 | Suggest tasks for a KR                  |

**New `analyzeOKR` prompt** (replaces old — now includes KR/Task analysis per user requirements):

```
You are an OKR methodology expert. Analyze the following Objective and its Key Results for adherence to OKR best practices.

## Input
- Objective Title: {{objective.title}}
- Objective Description: {{objective.description}}
- Key Results: {{kr_list}}
- Tasks: {{task_list}}

## Analysis Criteria
1. Is the Objective inspirational, qualitative, and time-bound?
2. For each KR, evaluate:
   - Alignment with the Objective
   - Measurability (has clear metrics)
   - Verifiability (can be objectively verified)
   - Outcome-oriented (not output/task-based)
   - Ambitious but realistic
3. Do the KRs collectively cover the Objective sufficiently?

## Output
Provide structured Markdown feedback with:
- Overall assessment
- Per-KR analysis (✅ strengths / ⚠️ improvements)
- Suggested optimized KR rewrites (if applicable)

**Output language: {{currentLanguage}}**
```

**New `suggestKR` prompt** (unchanged logic, same JSON output):

```
You are an OKR expert. Suggest 3-5 measurable Key Results for the following Objective.
Each KR must be: Aligned, Verifiable, Measurable, Outcome-oriented, Ambitious but realistic.

Objective: "{{objective.title}}"
Context: "{{objective.description}}"

Return ONLY a JSON array of strings. No markdown, no explanation.
**Output language: {{currentLanguage}}**
```

**New `suggestTask` prompt**:

```
Suggest 3-5 concrete tasks/actions to help achieve this Key Result.
Return ONLY a JSON array of strings. No markdown, no explanation.

Key Result: "{{keyResult.title}}"
**Output language: {{currentLanguage}}**
```

**New `evaluateKR` prompt** (for KR Suggest button in AddKeyResultView):

```
You are an OKR methodology expert. Evaluate the following Key Result against OKR standards.

Objective: "{{objective.title}}"
Key Result: "{{kr.title}}"

Evaluate on:
1. Aligned with Objective — Is it strongly related?
2. Verifiable — Can completion be objectively verified?
3. Measurable — Does it have a clear metric?
4. Outcome-oriented — Is it a result, not a task/output?
5. Ambitious but realistic — Is it stretching yet achievable?

Provide:
- A brief verdict for each criterion (✅ / ⚠️ / ❌)
- One optimized rewrite of the KR that meets all criteria

Format as Markdown. Mark the optimized KR with `> **Suggested:** ...` so the user can identify and copy it.
**Output language: {{currentLanguage}}**
```

#### Files to Modify/Create

##### [NEW] [PromptManager.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Services/AIProvider/PromptManager.swift)

- `PromptTemplate` enum: `analyzeOKR`, `suggestKR`, `suggestTask`, `evaluateKR`
- Each has a `defaultTemplate(for locale: String)` returning localized default
- `PromptManager` class stores custom prompts in `UserDefaults` keyed by `"prompt_{id}_{lang}"`
- `resolvedPrompt(for:objective:keyResult:locale:)` replaces `{{...}}` placeholders with actual data

##### [NEW] [PromptSettingsView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Settings/PromptSettingsView.swift)

- Lists each prompt template with name/description
- Clicking a prompt opens `MarkdownEditorView` for editing
- "Reset to Default" button per prompt
- Preview mode via `MarkdownEditorView`'s existing toggle

##### [MODIFY] [SettingsView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Settings/SettingsView.swift)

- Add `PromptSettingsView()` tab after AI tab with label `"Prompts"` and icon `"text.bubble"`

##### [MODIFY] [AIService.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Services/AIProvider/AIService.swift)

- Replace all hardcoded prompts with `PromptManager.shared.resolvedPrompt(...)` calls
- Collapse duplicate `analyzeWith{Provider}` / `suggestWith{Provider}` methods into single prompt → provider routing
- Add new `evaluateKeyResult(_:for:)` method

---

### 1.2 Objective Draft – Analyze with AI & UI Optimization

##### [MODIFY] [EditObjectiveView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Objectives/EditObjectiveView.swift)

- Replace plain `TextEditor` for description with `MarkdownEditorView` (same as Task detail)

##### [MODIFY] [ObjectiveListView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveListView.swift)

- **Icon change**: Replace `arrow.up.circle` (↑) with `magnifyingglass` in `ObjectiveRowView`
- **Button style**: Make it a bordered/bezel button with proper color handling for selected vs unselected state
- **AI Analysis**: Update `analyzeObjective()` to use new `PromptManager` with KR+Task data included

##### [MODIFY] [AddObjectiveView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Objectives/AddObjectiveView.swift)

- Replace description `TextField` with `MarkdownEditorView`

---

### 1.3 New Key Result Window Optimization

##### [MODIFY] [AddKeyResultView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/KeyResults/AddKeyResultView.swift)

- **Auto-focus**: Add `.onAppear { isTitleFocused = true }` with `@FocusState`
- **Remove Detail section**: Delete `Section("Details")` label and the info texts ("Progress will be calculated..." / "Add tasks after creating...")
- **Suggest button**: Disable when `title.isEmpty`; change functionality from "suggest new KRs" to "evaluate this KR" using new `evaluateKR` prompt
- **Evaluation sheet**: Show structured evaluation result in Markdown; include the suggested optimized KR line that user can copy (`.textSelection(.enabled)`)

---

## Phase 2: Review Mode Redesign

> [!IMPORTANT]
> **Delete all existing Review mode logic and UI.** Replace with per-Objective review records that can be created, stored, and viewed historically.

### 2.1 Delete Existing Review Mode

##### [DELETE] [ReviewSettingsView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Settings/ReviewSettingsView.swift)

##### [MODIFY] [ReviewModeManager.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Services/ReviewModeManager.swift)

- Remove `isInReviewMode`, `enterReviewMode()`, `exitReviewMode()`, `canEditOKR()`, `canEditTask()` methods
- Keep notification/reminder functionality (repurposed as review reminders)

##### [MODIFY] [ObjectiveListView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveListView.swift)

- Remove bottom Review Mode toggle button
- Remove `onChange(of: ReviewModeManager.shared.isInReviewMode)`

##### [MODIFY] [SettingsView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Settings/SettingsView.swift)

- Remove Review tab (notification settings can move to General or be accessed per-Objective)

##### [MODIFY] [Objective.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/Objective.swift) / [KeyResult.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/KeyResult.swift) / [OKRTask.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/OKRTask.swift)

- Simplify `isEditable`: remove ReviewModeManager dependency, base on status only (draft/active = editable, achieved/archived = read-only)

##### [MODIFY] [OKRStatus.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/Enums/OKRStatus.swift)

- Remove `.review` case (no longer needed)

---

### 2.2 New Review Data Model

##### [NEW] [OKRReview.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/OKRReview.swift)

```swift
@Model
final class OKRReview {
    @Attribute(.unique) var id: UUID
    var reviewType: ReviewType      // .weekly, .midCycle, .endCycle
    var createdAt: Date
    var overallNotes: String        // general commentary

    var objective: Objective?

    @Relationship(deleteRule: .cascade, inverse: \KRReviewEntry.review)
    var krEntries: [KRReviewEntry] = []
}
```

##### [NEW] [KRReviewEntry.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/KRReviewEntry.swift)

```swift
@Model
final class KRReviewEntry {
    @Attribute(.unique) var id: UUID
    var currentValue: Double        // current metric value
    var targetValue: Double         // target metric value
    var completionPercent: Double   // auto-calculated or manual
    var trend: ReviewTrend          // .up, .down, .flat
    var status: KRReviewStatus      // .onTrack, .atRisk, .offTrack, .blocked
    var statusReason: String        // why this status
    var progress: String            // key achievements
    var blockers: String            // impediments
    var nextSteps: String           // planned actions
    var adjustmentNotes: String     // any KR target/strategy changes
    var createdAt: Date

    var keyResult: KeyResult?
    var review: OKRReview?
}
```

##### [NEW] [ReviewType.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/Enums/ReviewType.swift)

```swift
enum ReviewType: String, Codable, CaseIterable {
    case weekly = "Weekly Check-in"
    case midCycle = "Mid-cycle Review"
    case endCycle = "End-cycle Review"
}
```

##### [NEW] [ReviewTrend.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/Enums/ReviewTrend.swift) + [KRReviewStatus.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/Enums/KRReviewStatus.swift)

##### [MODIFY] [Objective.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Models/Objective.swift)

- Add `@Relationship(deleteRule: .cascade, inverse: \OKRReview.objective) var reviews: [OKRReview] = []`

##### [MODIFY] [SoloOKRsApp.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/SoloOKRsApp.swift)

- Add new models to `ModelContainer` schema: `OKRReview.self`, `KRReviewEntry.self`

---

### 2.3 New Review UI

##### [NEW] [CreateReviewView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Reviews/CreateReviewView.swift)

- Sheet/form to create a new review for a specific Objective
- Select `ReviewType`
- Auto-populates a `KRReviewEntry` for each KR in the Objective
- For each KR entry: fields for currentValue, targetValue, status picker, trend picker, progress, blockers, nextSteps
- "Save" creates `OKRReview` + entries

##### [NEW] [ReviewHistoryView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Reviews/ReviewHistoryView.swift)

- Shows all past reviews for a given Objective, sorted by date
- Each review row shows: date, type, overall status summary
- Tapping a review opens detail view

##### [NEW] [ReviewDetailView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Reviews/ReviewDetailView.swift)

- Read-only display of a completed review
- Shows overall notes + each KR entry with all fields

##### [MODIFY] [ObjectiveListView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveListView.swift)

- Add "New Review" context menu item for active Objectives
- Replace old Review Mode bottom bar with "Reviews" navigation to `ReviewHistoryView`

##### [MODIFY] [ContentView.swift](file:///Users/kane/Code/SoloOKRs/src/SoloOKRs/SoloOKRs/ContentView.swift)

- May need to add navigation to review history / detail views

---

## Verification Plan

### Automated

- **Build verification**: `xcodebuild build -project src/SoloOKRs/SoloOKRs.xcodeproj -scheme SoloOKRs -destination 'platform=macOS'`
- Confirm zero build errors and zero new warnings

### Manual Verification (User)

1. **Settings → Prompts tab**: Open Settings, verify Prompts tab appears after AI tab, all 4 prompts listed, each editable with Markdown editor, "Reset to Default" works
2. **Objective Analyze**: In Draft tab, verify magnifying glass icon appears as a button, clicking opens AI analysis with KR/Task data included in prompt
3. **AddKeyResultView**: Verify cursor auto-focuses on title, no Detail label, Suggest button disabled until title typed, evaluation sheet shows structured analysis with copyable suggested KR
4. **Review — Create**: Right-click active Objective → "New Review", fill KR entries, save
5. **Review — History**: View past reviews for an Objective, tap to see detail
6. **Localization**: Switch language, verify prompts display in correct language, AI output respects language setting
