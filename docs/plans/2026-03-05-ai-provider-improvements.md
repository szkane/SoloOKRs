# AI Provider Improvements Implementation Plan

**Goal:** Configure all AI providers completely, improve the provider selection UI (non-dropdown model list and auto-refresh), and implement missing API integrations (OpenAI-compatible for Custom/LM Studio/OpenAI, and Anthropic).

## Proposed Changes

### Configuration UI & Model Selection

#### [MODIFY] AIProviderSettingsView.swift

- **Fetch Models on Provider Change:** Update the `.onChange(of: aiService.selectedProviderType)` modifier to automatically call `aiService.fetchModels()` if the chosen provider `isConfigured`.
- **Custom Provider Config:** Add a `customAPIKey` (optional) field to the `.custom` settings section and load its models.
- **Model List UI:** Refactor `modelSelectionView`. Replace the dropdown `Picker(..., style: .menu)` with a standard non-dropdown list view (e.g., a scrollable `VStack` or `List` showing available models with a system checkmark for the selected item). Show this only after configuration verification succeeds.

### Service Layer & OpenAI Compatibility

#### [MODIFY] AIService.swift

- **Custom Keys:** Add `customAPIKey` to `AIService` backed by Keychain (similar to `openAIAPIKey`).
- **OpenAI-Compatible Gen:** Implement a generic `generateWithOpenAICompatible(prompt: String, endpoint: String, apiKey: String, model: String) async throws -> String` method using the standard `/v1/chat/completions` API schema.
- **Anthropic Gen:** Implement `generateWithAnthropic(prompt: String) async throws -> String` using the `/v1/messages` format.
- **Routing:** Update the switch statements in `analyzeOKR`, `suggestKeyResults`, and `suggestTasks` to route `.openai`, `.lmstudio`, and `.custom` to the `generateWithOpenAICompatible` method. Route `.anthropic` to `generateWithAnthropic`.
- **Fetch Models update:** Ensure `.custom` fetches models from `<customEndpoint>/v1/models` using the new `customAPIKey`.

#### [MODIFY] .agent/workflows/init.md

- **Reference Plan:** Update the `Implementation Plan` pointer to `docs/plans/2026-03-05-ai-provider-improvements.md`.

## Verification Plan

### Automated Tests

- Run `xcodebuild -scheme SoloOKRs build` locally to verify build succeeds after code changes.

### Manual Verification

- Open Settings -> AI Providers. Switch between Gemini, OpenAI, and Ollama to verify `fetchModels()` fires automatically if keys/endpoints are present.
- Verify the new non-dropdown list UI for models appears once verified.
- Input a custom provider endpoint alongside an API key, select a model, and execute `Suggest Key Results` for an Objective to ensure OpenAI-compatible APIs work.
