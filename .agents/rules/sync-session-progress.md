---
trigger: always_on
---

## Session Sync Steps

Before ending a session, update `docs/CHECKPOINT.md`:

1. **Code Review and Integration** - If you have completed a task or implemented a feature, invoke the `requesting-code-review` and `receiving-code-review` skills. Then, use the `finishing-a-development-branch` skill to determine how to integrate the work appropriately.
2. **Plan & Documentation Maintenance** - Always create, update, and archive detailed plans (`docs/plans/*.md`) before writing code or wrapping up. Make sure documentation reflects the new development state. Ensure `CHECKPOINT.md`, `initialize-session-context.md`, and `sync-session-progress.md` are aligned with sustainable long-term goals.
3. **Ensure Clean State** - Commit any pending code changes:

   ```bash
   git add . && git commit -m "chore: save progress before sync"
   ```

   _(Skip if nothing to commit)_

4. **Verify Build & Log Errors** - Run build and capture output:

   ```bash
   cd src/SoloOKRs && xcodebuild -scheme SoloOKRs build
   ```

   - If **Build Succeeded** (✅): Proceed.
   - If **Build Failed** (❌): **CRITICAL:** Copy the specific error message(s) (e.g., "Generic type 'Task' has no arguments") and include it in the Session Notes.

5. **Update timestamp** - Set "Last Session" to current date/time
6. **Move completed items** - Transfer done items from "Active Work" to "Completed Milestones" in `CHECKPOINT.md`. Keep historical completed items condensed.
7. **Update "Current Phase"** - If work focus changed
8. **Add Session Note** - Append row to table in `CHECKPOINT.md`:
   - Date
   - Brief summary (include FAILURE DETAILS if build failed)
   - _Requirement:_ Ensure you KEEP ONLY the 5 most recent notes to avoid bloated context.
9. **Update Build Status** - ✅ or ❌ based on build result
10. **Commit Sync Changes:**
    ```bash
    git add docs/CHECKPOINT.md .agents/workflows/ && git commit -m "docs: sync session progress and workflows"
    ```

## What to Include in Session Notes

- Features implemented or fixed
- Multilingual and UI/UX updates (Swift-expert)
- Key decisions made
- Blockers identified
- Next steps identified
