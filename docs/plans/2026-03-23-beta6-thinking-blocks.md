# Beta 6: Collapsible AI Thinking Blocks

When AI models (especially DeepSeek, QwQ, etc.) include reasoning/thinking processes wrapped in `<think>...</think>` tags, these should be collapsed by default, shown in a smaller font, and include a thinking animation — instead of rendering inline as raw text.

## Changes

### New Files
- `Utilities/ThinkingBlockParser.swift` — Splits AI response text into content/thinking segments
- `Views/Components/AIResponseView.swift` — Reusable view with collapsible thinking disclosure groups

### Modified Files
- `Views/Objectives/ObjectiveListView.swift` — `Markdown(result)` → `AIResponseView`
- `Views/KeyResults/EditKeyResultView.swift` — Same replacement
- `Views/KeyResults/AddKeyResultView.swift` — Same replacement
- `Resources/Localizable.xcstrings` — Added "Thinking" key (9 languages)

## Build Status
✅ Verified 2026-03-23
