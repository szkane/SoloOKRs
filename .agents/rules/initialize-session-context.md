---
trigger: always_on
---

## Session Initialization

1. Invoke the `using-superpowers` skill to set up expectations for skill usage in this session.
2. Read `docs/CHECKPOINT.md` for current project state
3. **CRITICAL CHECK:** Look at "Build Status".
   - If **❌ (Failed)**: Your **IMMEDIATE PRIORITY** is to fix the build errors listed in "Session Notes". Do not start new features until the build is green.
   - If **✅ (Success)**: Proceed to standard planning.

4. Review "Active Work" section for immediate context
5. Check "Session Notes" for recent conversation history
6. Verify build state locally:

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build -destination 'platform=macOS,arch=arm64' > /tmp/build_log.txt 2>&1 || grep -A 5 -B 5 "error:" /tmp/build_log.txt
```

## 🧠 Development Guidelines & Best Practices

Before generating code, strictly adhere to the following project guidelines based on historical conventions:

1. **Planning First:** Always create and archive a detailed plan before writing code and Save the implementation plan to the `docs\plan\` folder using the `YYYY-MM-DD-*.md` filename format, for example, `2026-03-05-beta3-improvements.md`. Update `CHECKPOINT.md` and agents rules to ensure sustainable long-term development context.
2. **Multilingual Support:** When adding or modifying features, ensure **full multilingual support** for the app (currently 9 languages: en, zh-Hans, zh-Hant, ja, ko, de, fr, es, pt-BR). Translated text must be length-adapted to the UI layout to avoid breaking the interface, and language switching MUST work in real time (e.g., leveraging `Localizable.xcstrings` and `\.locale` environment injections).
3. **UI/UX Consistency:** For UI/UX updates, MUST use **swift-expert** skills to maintain a consistent, Apple-native user experience. Ensure clear loading states, error handling, padding, and smooth macOS integrations.
4. **Security & Data:** Use local Keychain (`kSecUseDataProtectionKeychain`) for sensitive data like API keys. Provide clear UI prompts when secure storage is used.
5. **Robustness:** Ensure proper memory management and concurrency (e.g. using Delegate patterns instead of capturing closures for MCP servers to avoid `EXC_BAD_ACCESS`). Make sure the build stays green during feature integration.

## Quick Reference

- **Source:** `src/SoloOKRs/SoloOKRs/`
- **Implementation Plan:** the latest timestamp doc in `docs/plans/`
- **Design Doc:** `docs/plans/2026-02-03-solo-okrs-design.md`
