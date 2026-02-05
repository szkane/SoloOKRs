---
description: Sync session progress to CHECKPOINT.md before ending
---

## Session Sync Steps

Before ending a session, update `docs/CHECKPOINT.md`:

1. **Update timestamp** - Set "Last Session" to current date/time
2. **Move completed items** - Transfer done items from "Active Work" to "Completed"
3. **Update "Current Phase"** - If work focus changed
4. **Add Session Note** - Append row to table:
   - Date
   - Brief summary of accomplishments
5. **Update Build Status** - ✅ or ❌ based on last build
6. **Commit changes:**

```bash
git add docs/CHECKPOINT.md && git commit -m "docs: sync session progress"
```

## What to Include in Session Notes

- Features implemented or fixed
- Key decisions made
- Blockers identified
- Next steps identified
