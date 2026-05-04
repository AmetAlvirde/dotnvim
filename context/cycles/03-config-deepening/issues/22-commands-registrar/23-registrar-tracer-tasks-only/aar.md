# AAR — Sub-issue #23: Registrar tracer + `ObsCLITasks` migration

1. **Did it go as planned?** Yes — straight execution of the sub-issue plan.

2. **What changed from the sub-issue plan:**

   Nothing. All six proposed-test cases were implemented as specified (the
   `(true, "")` and `(true, nil)` silent branches each became their own case,
   for seven total, matching the "same case for `(true, nil)`" note in the
   sub-issue). The interface design was confirmed unchanged from the sub-issue.
   `ObsCLITasks` migrated cleanly. No second consumer surfaced; the promotion
   of the registrar to `lua/utils/` remains deferred.

3. **Carry-forward:**

   **Registrar location decision (resolved through implementation):**
   `lua/config/commands_registrar.lua`. Reason: lowest-friction option that
   keeps the registrar `require`-able and testable in isolation without
   top-level side-effects from `commands.lua`. The other 17 commands remain on
   inline shape; no second consumer surfaced; promotion to `lua/utils/` stays
   deferred. Recorded in parent `issue.md` under "Implementation approach".

   **Spec-row schema decision (resolved through implementation):**
   Required keys `name`, `desc`, `module`, `fn`; optional `args` (default
   `{}`), `on_load_error` (default `"Failed to load " .. spec.module`).
   Optional forwards (`nargs`, `complete`, `range`, `bang`) held for
   subsequent sub-issues as commands needing them migrate. Schema is the
   exact Alternative A shape from the sub-issue interface section.

   **Deliberate-failure verification:**
   Mutated `vim.log.levels.ERROR` → `vim.log.levels.INFO` on the leaf-failure
   branch of `commands_registrar.lua` (line 17). Exactly one case went red:
   "register: leaf returns (false, msg): one ERROR notify with msg". No other
   cases were affected. Reverted; suite returned to 99/99 green.

   **Flags for subsequent sub-issues:**
   None. The test pattern (pre_case/post_case stubs, `package.loaded` stub
   leaf, no `mini.test.new_child_neovim`) is confirmed working and inheritable
   directly by the remaining migration sub-issues (Candidates B and D's seams,
   and the subsequent `commands.lua` migration batches).

   **Notes for parent issue AAR:**
   The ADR-0004 candidacy for the registrar pattern remains deferred until at
   least one more seam (Candidate B or D) is in place, per cycle PRD open
   question 4. The Candidate F (domain split of `commands.lua`) decision
   is the closing sub-issue of parent #22; no signal yet on whether it
   lands or is skipped.
