---
description: Sync session progress to CHECKPOINT.md before ending
---

## Session Sync Steps

Before ending a session, update `docs/CHECKPOINT.md`:

1. **Ensure Clean State** - Commit any pending code changes:

   ```bash
   git add . && git commit -m "chore: save progress before sync"
   ```

   _(Skip if nothing to commit)_

2. **Verify Build & Log Errors** - Run build and capture output:

   ```bash
   cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build
   ```

   - If **Build Succeeded** (✅): Proceed.
   - If **Build Failed** (❌): **CRITICAL:** Copy the specific error message(s) (e.g., "Generic type 'Task' has no arguments") and include it in the Session Notes.

3. **Update timestamp** - Set "Last Session" to current date/time
4. **Move completed items** - Transfer done items from "Active Work" to "Completed"
5. **Update "Current Phase"** - If work focus changed
6. **Add Session Note** - Append row to table:
   - Date
   - Brief summary (include FAILURE DETAILS if build failed)
7. **Update Build Status** - ✅ or ❌ based on build result
8. **Commit Sync Changes:**
   ```bash
   git add docs/CHECKPOINT.md && git commit -m "docs: sync session progress"
   ```

## What to Include in Session Notes

- Features implemented or fixed
- Key decisions made
- Blockers identified
- Next steps identified
