---
description: Initialize session context for SOLO OKRs development
---

## Session Initialization

// turbo-all

1. Read `docs/CHECKPOINT.md` for current project state
2. **CRITICAL CHECK:** Look at "Build Status".
   - If **❌ (Failed)**: Your **IMMEDIATE PRIORITY** is to fix the build errors listed in "Session Notes". Do not start new features until the build is green.
   - If **✅ (Success)**: Proceed to standard planning.

3. Review "Active Work" section for immediate context
4. Check "Session Notes" for recent conversation history
5. Verify build state locally:

```bash
cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build 2>&1 | tail -5
```

## Quick Reference

- **Source:** `src/SoloOKRs/SoloOKRs/`
- **Implementation Plan:** `docs/plans/2026-02-06-post-beta-improvements.md`
- **Design Doc:** `docs/plans/2026-02-03-solo-okrs-design.md`
