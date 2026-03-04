---
description: Sync session progress to CHECKPOINT.md before ending
---

## Session Sync Steps

Before ending a session, update `docs/CHECKPOINT.md`:

1. **Code Review and Integration** - If you have completed a task or implemented a feature, invoke the `requesting-code-review` and `receiving-code-review` skills. Then, use the `finishing-a-development-branch` skill to determine how to integrate the work appropriately.
2. **Ensure Clean State** - Commit any pending code changes:

   ```bash
   git add . && git commit -m "chore: save progress before sync"
   ```

   _(Skip if nothing to commit)_

3. **Verify Build & Log Errors** - Run build and capture output:

   ```bash
   cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build
   ```

   - If **Build Succeeded** (✅): Proceed.
   - If **Build Failed** (❌): **CRITICAL:** Copy the specific error message(s) (e.g., "Generic type 'Task' has no arguments") and include it in the Session Notes.

4. **Update timestamp** - Set "Last Session" to current date/time
5. **Move completed items** - Transfer done items from "Active Work" to "Completed"
6. **Update "Current Phase"** - If work focus changed
7. **Add Session Note** - Append row to table:
   - Date
   - Brief summary (include FAILURE DETAILS if build failed)
8. **Update Build Status** - ✅ or ❌ based on build result
9. **Commit Sync Changes:**
   ```bash
   git add docs/CHECKPOINT.md && git commit -m "docs: sync session progress"
   ```

## What to Include in Session Notes

- Features implemented or fixed
- Key decisions made
- Blockers identified
- Next steps identified
