# AAR — PRD Cycle: Deepen `utils.obsidian_cli`

1. **Did it go as planned? Yes** — One parent issue (#13), seven sub-issues, all
   closed with matching AARs; acceptance criteria and success metrics satisfied;
   `./tests/run` reports 92 cases, 0 fails (verified at closure with Neovim on
   PATH); `lua/config/commands.lua` unchanged for the cycle; ADR-0003 accepted
   at parent closure per plan.

2. **What changed from the PRD plan:**

   - **Shell-adapter constraint (letter):** After sub-issue #20, two module-level
     setter seams exist — `shell.set_runner` / `shell.reset_runner` and
     `parsers.set_resolver` / `parsers.reset_resolver` — both documented in the
     parent AAR and in ADR-0003 consequences. The spirit of “named seam, no
     monkey-patched globals” is unchanged.
   - **Presenter** remains integration-tested only via leaf paths; no presenter
     unit tests landed. Aligns with PRD non-goal #4 and the PRD **Flags**
     section (presenter testability deferred).
   - **Backlinks:** Pure JSON parser coverage closed in #19; two distinct
     user-facing branches in `M.backlinks_counts_to_quickfix` remain untested
     at the integration path (recorded as a flag).
   - **`vault_relpath_to_abs`** duplication across `init.lua` and `parsers.lua`
     noted as a deepening candidate flag, not a cycle requirement.

3. **ADRs made during this cycle** (see `context/adr/INDEX.md`):

   | #     | Title                                           | Status   |
   | ----- | ----------------------------------------------- | -------- |
   | 0003  | Four-layer subpackage for shell-bound utilities | accepted |

   ADR-0001 and ADR-0002 pre-existed.

4. **New considerations or constraints surfaced:**

   - Setter seams can extend to non-shell impurity inside otherwise pure layers
     (`parsers.set_resolver` precedent) without restructuring the subpackage.
   - Fixture text files under `tests/utils/obsidian_cli/fixtures/` worked well
     for parser tests.
   - `require("utils.obsidian_cli")` resolving to `init.lua` stayed a stable
     load point through the cycle.

5. **Proposed future features or ideas** (from PRD **Flags** — still open for
   future pitches, not cycle 03 scope unless explicitly pulled in):

   - Presenter testability (pure transform vs child Neovim).
   - Backlinks integration-path coverage for `M.backlinks_counts_to_quickfix`.
   - Consolidate `vault_relpath_to_abs` into a shared module / reuse resolver at
     bookmark callsites.

6. **Patterns across parent issue AARs:**

   - Single parent issue **#13**; its AAR covers all seven sub-issues. Pattern:
     pre-activation and documented interface choices (#14, #20) reduced rework.

7. **Carry-forward to the next cycle:**

   - **Cycle 03** (`context/cycles/03-config-deepening/prd.md`) picks up
     configuration deepening (commands registrar, theme seam, highlights,
     macOS codesign, etc.) per its own PRD. No edits to cycle 03 artifacts are
     required solely to close cycle 02.
   - **Unresolved Obsidian follow-ups** remain recorded as unchecked flags on
     `context/cycles/02-obsidian-cli/prd.md` for future cycles that choose to
     deepen `obsidian_cli` again.

8. **Cycle decision: feature complete** — The cycle’s committed PRD scope
   (four-layer submodule, shell/parser seams, parser and builder coverage,
   stable `M.*` surface, no `commands.lua` churn) is delivered and documented.
   Further product work continues in **new cycles** (e.g. cycle 03 and beyond),
   not as unfinished obligations within this PRD. No pivot: behavior matches
   `context/product.md` intent for this configuration.
