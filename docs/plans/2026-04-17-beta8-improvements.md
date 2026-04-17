# Beta 8 Implementation Plan

This plan addresses the three core requirements for the Beta 8 release.

## User Review Required

Please review the proposed prompt text changes for the AI prompts. I have shortened the outputs and added clear next-step guidance as requested, while keeping the core analysis intact. Let me know if you would like me to adjust the prompt phrasing further.

## Proposed Changes

### 1. Appearance Mode Switcher (Settings & App)
We will introduce a new `AppStorage` variable to manage the user's preferred appearance (System, Light, Dark) and apply it globally.

#### [MODIFY] `src/SoloOKRs/SoloOKRs/Views/Settings/GeneralSettingsView.swift`
- Add `@AppStorage("appearance") private var appearance = "system"`
- Update the Appearance `Section` to use a `Picker` instead of the static text.
- Options will be: System ("system"), Light ("light"), Dark ("dark").
- Use `.pickerStyle(.segmented)` or `.radioGroup` for clarity.

#### [MODIFY] `src/SoloOKRs/SoloOKRs/SoloOKRsApp.swift`
- Add `@AppStorage("appearance") private var appearance = "system"`
- Add an extension or property to convert this string to an optional `ColorScheme`.
- Apply `.preferredColorScheme(colorScheme(for: appearance))` to the main `ContentView()`, `Settings`, and `Window`s.

### 2. Prompt Enhancements (Analyze, Suggest, Evaluate)
We need to update the AI prompt templates and variable injection to provide better, more concise output, with start/end dates for analysis.

#### [MODIFY] `src/SoloOKRs/SoloOKRs/Services/AIProvider/PromptManager.swift`
- **Analyze OKR Data Injection**:
  - In `resolvedAnalyzePrompt(for:)`, add string replacements for `{{objective.startDate}}` and `{{objective.endDate}}` using a formatted date string (e.g., `formatted(date: .abbreviated, time: .omitted)`).
- **Analyze OKR Prompt Template**:
  - Update `defaultPrompt` for `.analyzeOKR` to include `- Start Date: {{objective.startDate}}` and `- End Date: {{objective.endDate}}`.
  - Modify output instructions: "Keep feedback concise and brief. Restrict output length. End with 1-2 clear, actionable next steps for the user."
- **Suggest KR Prompt Template**:
  - Update `defaultPrompt` for `.suggestKR`. Modify the JSON instruction to ensure each KR is "a complete, single sentence that is easy to read."
- **Evaluate KR Prompt Template**:
  - Update `defaultPrompt` for `.evaluateKR`.
  - Modify output instructions: "Keep feedback extremely concise. Restrict output length. End with clearly defined next-step guidance on how to fix the KR."

### 3. Objective Title UI Update
Make the Objective list UI uniform, handling two-line titles.

#### [MODIFY] `src/SoloOKRs/SoloOKRs/Views/Objectives/ObjectiveListView.swift`
- Inside `ObjectiveRowView`:
  - Locate `Text(objective.title)`.
  - Add `.lineLimit(2)`.
  - Add `.multilineTextAlignment(.leading)`.
  - Enforce a specific minimum height or fixed height on the text/title container so the row maintains a uniform height regardless of whether the title is 1 or 2 lines (e.g., wrap it in a container with a fixed frame or add `.frame(minHeight: 45, alignment: .topLeading)` to the title block).

## Verification Plan

### Manual Verification
1. Open settings, switch Appearance between Light, Dark, and System, and verify the app immediately changes `.colorScheme`.
2. Select an Objective, click "Analyze with AI" and review the AI output. Ensure it is concise, contains start/end date context, and includes next-step guidance.
3. Use the "Suggest Key Results" or "Evaluate Key Result" features and observe the shortness and clear sentence structuring.
4. Add a lengthy Objective title and observe that it wraps cleanly to two lines and the overall row height matches other 1-line rows.
