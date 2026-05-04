# AAR — Parent Issue #13: Deepen `utils.obsidian_cli`

1. **Did it go as planned? Yes** — all 7 sub-issues closed with "Yes"; all
   acceptance criteria satisfied; suite landed at 92 cases, 0 fails; ADR-0003
   authored at closure as planned.

2. **What changed from the parent issue plan:**

   - **Constraint #3 amended (letter, not spirit):** the original constraint
     read "the shell-adapter setter is the seam." After #20, two module-level
     setter seams exist:
     - `shell.set_runner(fn)` / `shell.reset_runner()` — wraps
       `vim.fn.systemlist`.
     - `parsers.set_resolver(fn)` / `parsers.reset_resolver()` — wraps
       `vault_relpath_to_abs` (`vim.loop.fs_stat` / `fs_realpath`),
       introduced in #20 to make `extract_bookmark_note_path` testable
       without disk access.
     Both are module-level, default to the real implementation on module load,
     and neither monkey-patches globals. The constraint's spirit — "test seams
     are explicit, restorable, and on named modules, not production signatures"
     — holds intact.

   - **ADR-0003 scoped to accommodate the parsers seam extension:** the
     "Consequences" section explicitly notes `parsers.set_resolver` as the
     first qualified extension of the pattern; the pattern was not structurally
     revised to accommodate it, which confirms durability.

   - **Presenter testability not resolved** (PRD non-goal #4 anticipated this).
     `presenter.lua` exists and is integrated, but has zero unit tests. Whether
     it can be tested as a pure `(parsed_items) → quickfix_payload`
     transformation or requires `mini.test.new_child_neovim` for editor-state
     isolation was not assessed in any sub-issue.

   - **Backlinks integration path deferred** (#19 closed the pure-parser
     sub-requirement; the two distinct user-facing messages in
     `M.backlinks_counts_to_quickfix` remain uncovered because they require
     the shell-adapter seam plus quickfix/scratch-buffer state assertions, or
     a child-Neovim spec).

   - **`vault_relpath_to_abs` duplication surfaced in #20:** the local function
     is duplicated in `init.lua` (line 33) and `parsers.lua` (lines 7–29).
     Extracting it to a fifth sibling would eliminate the duplication and make
     the resolver seam reusable at the `init.lua` bookmark-keymap callsite.
     Recorded as a deepening candidate.

3. **ADRs made during this parent issue:**

   | # | Title | Status |
   |---|---|---|
   | 0003 | Four-layer subpackage for shell-bound utilities | accepted |

   ADR-0001 and ADR-0002 were pre-existing. ADR-0003 was deferred from the
   PRD until the pattern proved durable across at least one sub-issue (per PRD
   open question #4); it proved durable across all 7 and was authored at
   parent closure.

4. **New considerations or constraints surfaced:**

   - The setter-seam pattern is extensible to non-shell impure helpers inside
     pure-layer modules (the `parsers.set_resolver` precedent). Future parser
     slices that touch the filesystem should follow the same pattern rather
     than restructuring the module.
   - Fixture files as plain text in `tests/utils/obsidian_cli/fixtures/` proved
     the right choice: fixtures are human-readable, durable, and require no
     fixture-generation step or binary data.
   - `lua/config/commands.lua` was untouched across all 7 sub-issues,
     confirming that the `require("utils.obsidian_cli")` → `init.lua`
     resolution is a stable load point.

5. **Patterns across sub-issue AARs:**

   - All 7 sub-issues answered "Did it go as planned? Yes." No replanning, no
     scope creep, no rejected interface candidates after pre-activation.
   - Incremental TDD (tracer bullet first, then one named case per behavior)
     kept each sub-issue to a predictable length and made regressions
     impossible to introduce silently.
   - The sub-issues that introduced the most design discussion (#14 layer
     skeleton, #20 bookmark resolver seam) were the ones where the plan
     pre-documented the decision before any code was written. That pattern
     should be preserved in future slices.

6. **Carry-forward — flags to write in the cycle PRD:**

   Three flags are written into `context/cycles/02-obsidian-cli/prd.md`:

   - `[#13 AAR → future cycle: presenter testability]` — `presenter.lua` has
     no unit tests; future cycle decides pure-transform vs child-Neovim.
   - `[#13 AAR → future cycle: backlinks integration-path coverage]` —
     `M.backlinks_counts_to_quickfix` has two uncovered branches; needs
     shell-seam + quickfix/child-Neovim assertions.
   - `[#13 AAR → future cycle: vault_relpath_to_abs consolidation]` —
     duplication in `init.lua` and `parsers.lua`; extract to fifth sibling.

   All three flags were pre-written into the PRD before this AAR. No
   additional flags arise from the sub-issue pattern review.
