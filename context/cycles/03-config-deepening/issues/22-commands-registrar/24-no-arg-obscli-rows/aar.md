# AAR — Sub-issue #24: No-arg ObsCLI commands migration batch

1. **Did it go as planned?** Yes — straightforward mechanical migration with no
   surprises.

2. **What changed from the sub-issue plan:**
   - Nothing. All six commands migrated as Alternative A spec rows, section
     comments and ordering preserved, 11 remaining inline commands byte-for-byte
     unchanged, no edits to `commands_registrar.lua`, no new specs added.
   - The acceptance-criteria note "Two such blocks remain — for
     `ObsCLISearchContext` and `ObsCLIBookmarkAdd`" in the sub-issue was
     inaccurate; seven `pcall(require, "utils.obsidian_cli")` inline blocks
     remain (`ObsCLISearchContext`, `ObsCLIHistoryRead`, `ObsCLIDiffFrom`,
     `ObsCLIOutline`, `ObsCLIBacklinks`, `ObsCLIWordCount`, `ObsCLIBookmarkAdd`).
     The intent — "the six migrated commands no longer carry inline blocks" — is
     correct; the count in the note was wrong. No action required; subsequent
     sub-issues inherit the correct seven-remaining picture.

3. **Carry-forward — flags, divergence notes, notes for parent AAR:**

   - **Line-count delta:** `commands.lua` dropped from 360 lines to 299 lines
     (−61 lines). Pre-sub-issue count was confirmed via `git show` on the
     pre-cycle state. The <120-line target for parent #22 closure still requires
     the remaining 11 migrations.

   - **Live smoke check (pending manual run):** Each of the six migrated commands
     must be invoked in a live Neovim session and confirmed to produce the same
     observable behavior as pre-migration. The commands and expected behavior:
     | Command | Expected behavior |
     | --- | --- |
     | `ObsCLITaskToggle` | Toggles the selected task in quickfix; ERROR notify on failure |
     | `ObsCLIOrphans` | Populates quickfix with orphan notes; ERROR notify on failure |
     | `ObsCLIDeadends` | Populates quickfix with dead-end notes; ERROR notify on failure |
     | `ObsCLIUnresolved` | Populates quickfix with unresolved links; ERROR notify on failure |
     | `ObsCLIHistory` | Opens history scratch buffer for current file; ERROR notify on failure |
     | `ObsCLIBookmarks` | Opens bookmarks scratch buffer; ERROR notify on failure |
     Record deviations here if found during the manual run.

   - **Deliberate-failure verification (pending manual run):** Swap one `fn`
     value to a non-existent key (e.g. `fn = "orphans_does_not_exist"`), invoke
     the command, observe the failure mode. If the registrar surfaces an ugly Lua
     error (nil-call trace) rather than a graceful ERROR notify, write a flag in
     parent #22 for a registrar-hardening sub-issue. Revert after. Record result
     here.

   - **No new flags for parent #22 at this time** (pending the manual runs
     above).

   - **Suite:** `./tests/run` exits 0, 99 cases, 0 failures. Cycle 01, 02, and
     registrar specs all green.
