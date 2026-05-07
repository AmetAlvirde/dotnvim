# Sub-issue #42 — Closing: decomposition audit + open-question resolutions

GitHub issue: #42. Fourth and closing sub-issue under parent #38
(Candidate C — `solarized.lua` highlight decomposition) of cycle
`03-config-deepening`. After this sub-issue closes, parent #38's
sibling `aar.md` lands and the cycle moves on to its PRD-close pass.

## Description

The structural reshape parent #38 set out to land is already in place
after #41:

- Eight section modules under `lua/colors/highlights/`
  (`lsp_diagnostic`, `base`, `syntax`, `treesitter`, `markdown`,
  `treesitter_markdown`, `obsidian`, `template_literals`), each
  exposing a pure `M.highlights(c) → table`.
- `lua/colors/solarized.lua`'s `setup()` body is exactly the shape
  from parent #38's implementation sketch: resolve theme → set
  background → SECTIONS compose loop into `merged` → single apply
  loop → `vim.g.colors_name = "solarized"` → `emit()`. The inlined
  `rest` table is gone. The trailing manual `vim.api.nvim_set_hl`
  block is gone. Exactly one `nvim_set_hl` call remains (the call
  inside the apply loop).
- Eight per-section specs under `tests/colors/highlights/`, plus
  the composition spec at `tests/colors/solarized_composition_spec.lua`
  exercising `setup("dark")` and `setup("light")` end-to-end through
  a faked apply loop.
- 183 cases in `./tests/run`, all green (per the #41 AAR).

What this closing sub-issue does:

1. **Audit pass** — walk every parent #38 acceptance criterion and
   record the verification command and its result against the
   post-#41 working tree. Document the audit in this sub-issue's
   AAR. No source changes if the audit comes back clean.
2. **Resolve cycle PRD open question #5 (composition-test depth)**
   — record the decision (representative-subset confirmed
   sufficient, deferred from #41's AAR) in this sub-issue's AAR
   along with the reasoning.
3. **Record the ADR-0004 carry-forward note** — whether the
   section-module pattern joins ADR-0004 ("module-local seam with
   public setter") or warrants its own ADR is a PRD-close call,
   per parent #38's issue.md. This sub-issue records the
   carry-forward note for the PRD-close pass; it does not make the
   ADR call itself.
4. **Land parent #38's sibling `aar.md`** — record the
   four-sub-issue arc (#39 → #40 → #41 → #42), surface any
   cross-cutting carry-forward into the cycle 03 PRD close, and
   confirm parent #38's flags list closes empty.

This is an audit + decision-record sub-issue. The pattern mirrors
#36 (parent #32's closure): no functional code change, no new
tests, decisions recorded in AAR, parent's sibling `aar.md` lands
as the deliverable.

Out of scope:

- Adding a full-table snapshot test for `setup()` — open Q #5's
  resolution is "representative-subset is sufficient" (deferred
  from #41 AAR). A snapshot would be churnier than the current
  subset for no demonstrated regression-detection benefit.
- Adding a key-uniqueness invariant test across SECTIONS modules
  — last-module-wins remains the merge contract, and codifying
  "no two modules share a key" would over-constrain future
  maintainers who may legitimately want an override pair.
- Adding the ADR for the section-module pattern. That decision
  belongs to the cycle 03 PRD-close pass, which compares the
  pattern against the registrar/subscribe/os_theme family already
  carrying ADR-0004 candidacy.
- Any code change to `lua/colors/solarized.lua`,
  `lua/colors/highlights/`, or `tests/colors/`. Audit reads only.

## Dependency classification

No new dependencies introduced. The audit reads existing files; no
new specs or modules land.

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `lua/colors/solarized.lua` (post-#41) | In-process | Already exercised by composition spec + per-section specs. No new spec. |
| `lua/colors/highlights/*.lua` (eight modules) | In-process | Each exercised by its own spec. No new spec. |
| `tests/colors/solarized_composition_spec.lua` | In-process | Already green at 183 cases per #41 AAR. No change. |
| `git` (audit reads pre-cycle baseline via `git show`) | True external (CLI) | Read-only; verified by inspecting `git show <pre-cycle-ref>:lua/colors/solarized.lua` against current file. |
| `grep` / `rg` (audit verification commands) | True external (CLI) | Read-only; verified by running and recording results in AAR. |

No interfaces change. No ports introduced.

## Interface design

The "interface" here is the audit checklist plus the AAR's decision
records. The design call is **how to scope the audit**.

### Alternative A — full structural audit + decision records (proposed)

Walk every parent #38 acceptance criterion in order, run the
verification command each AC names (or a documented equivalent),
record the result in this sub-issue's AAR. Resolve open Q #5 and
record the ADR-0004 carry-forward note in the same AAR. Parent
#38's sibling `aar.md` then summarizes the four-sub-issue arc.

**Pros:** Each parent AC has a paper trail. A reader of the parent
`aar.md` six months from now can see *which command verified each
claim*, not just "everything passed." Aligns with the cycle's
treatment of closure as a real verification step (parent #32 closure
in #36 followed the same shape: each AC walked, each command run).

**Cons:** Verbose AAR. Mitigated by collapsing the audit table —
one row per AC, with command and outcome columns — rather than
prose paragraphs.

### Alternative B — light closure ("ran the suite, all green, decisions recorded")

Skip the per-AC audit walk. Record `./tests/run` and
`PATH=/usr/bin:/bin ./tests/run` results, run a couple of spot-check
greps, record the open-Q decisions, and call it done.

**Pros:** Faster to write.

**Cons:** Loses the audit paper trail. Future cycles auditing
"how did we know parent #38 actually closed?" find only a green
test run, not a per-AC verification record. The structural ACs
(no `rest` table, no trailing block, exactly one `nvim_set_hl`
call) are not captured by the test suite alone — they need
direct file inspection to verify.

### Alternative C — full structural audit + add a regression-guard invariant test

Same as A, plus write one new test that codifies the post-cycle
invariant — e.g., "the SECTIONS list contains exactly eight entries
in the documented order" or "no two section modules share a key."

**Pros:** Codifies an invariant in the suite for future regressions.

**Cons:** The order test over-constrains: SECTIONS order is a
read-order convention, not load-bearing (per #41 AAR — Alternative
A means no two modules share a key, so any order produces the same
`merged`). Codifying the order forces a test update on every
intentional reordering. The key-uniqueness test over-constrains in
the other direction: last-module-wins remains the merge contract,
and a future override pair (e.g., a colorblind-mode overlay
section) would have to be reframed around the test rather than the
test serving the design. Both candidates fail the "test serves the
design" smell-test from cycle 02's TDD work.

### Chosen (proposed; final in AAR)

**Alternative A.** Full structural audit walked AC-by-AC, decisions
recorded in this sub-issue's AAR, parent #38's sibling `aar.md`
lands as the deliverable. No new code or tests.

**Reason for A:** Audit paper trail per AC is the durable artifact;
the decisions on open Q #5 and ADR-0004 carry-forward have natural
homes in the AAR; no demonstrated need for a regression-guard
invariant test surfaced during #39–#41.

**Rejected B:** loses the per-AC paper trail; structural ACs need
direct file inspection that the suite alone does not provide.

**Rejected C:** over-constrains the design — order is convention,
key-uniqueness is a current property not a binding contract.

### Audit checklist (the closing sub-issue's deliverable)

The audit walks parent #38's twelve acceptance-criterion bullets
plus the four resolved-through-implementation decision bullets.
Each row records: AC text (abbreviated), verification command (or
inspection step), and outcome (✓ pass, ✗ fail, ⚠ deviation noted).

| # | AC | Verification command | Expected outcome |
| --- | --- | --- | --- |
| 1 | `lua/colors/highlights/` is a directory of section modules; each pure `M.highlights(c) → table` | `ls lua/colors/highlights/` + `grep -rn 'vim\.' lua/colors/highlights/` | 8 files; zero `vim.*` matches |
| 2 | `solarized.lua`'s `setup()` no longer contains the inlined highlight table | `git show <pre-cycle-ref>:lua/colors/solarized.lua` vs. current | inlined `rest` block absent |
| 3 | Trailing manual `nvim_set_hl` calls folded into section modules | `grep -n 'nvim_set_hl' lua/colors/solarized.lua` | exactly 1 match (the apply loop) |
| 4 | Each section module has at least one passing unit test | `ls tests/colors/highlights/` + `./tests/run --filter colors.highlights` (or full run) | 8 spec files; all cases pass |
| 5 | Composition-level spec exercises `setup()` end-to-end | inspect `tests/colors/solarized_composition_spec.lua` + run | spec exists; cases green |
| 6 | Highlight output preserved (subset assertions) | composition-spec subset assertions for `setup("dark")` and `setup("light")` | all subset assertions pass |
| 7 | No edits to forbidden files | `git diff --name-only <pre-cycle-ref>...HEAD -- lua/colors/os_theme.lua lua/config/autocmds.lua lua/plugins/lualine.lua lua/config/commands.lua lua/config/commands_registrar.lua lua/utils/obsidian_cli/ lua/utils/wordcount.lua lua/utils/macos_codesign/` | empty output |
| 8 | Palette tables byte-for-byte unchanged; public surface preserved | `git show <pre-cycle-ref>:lua/colors/solarized.lua` vs. current — diff lines 31–100 (palettes) and `M.subscribe`/`set_theme`/`toggle`/`setup` signatures | no diff in palette block; signatures unchanged |
| 9 | `./tests/run` exits 0 on the whole suite | `./tests/run` | exit 0; no failures |
| 10 | `PATH=/usr/bin:/bin ./tests/run` exits 0 | `PATH=/usr/bin:/bin ./tests/run` | exit 0; no failures |
| 11 | No reaching into module locals or monkey-patching internals in any spec | `grep -rn 'package\.loaded' tests/colors/` + `grep -rn 'mini\.test\.finally' tests/colors/` | only sanctioned per-test swaps |
| 12 | Section-partition decision recorded | inspect #39 AAR + #40 AAR | partition resolved (lsp_diagnostic alone in #39; base/syntax/treesitter in #40; markdown/treesitter_markdown/obsidian/template_literals in #41) |
| 13 | Merge-order decision recorded | inspect #39 AAR + #41 AAR | last-module-wins resolved in #39; collapsed to single-definition in #41 |
| 14 | Composition-test depth decision recorded | resolve in this sub-issue's AAR | representative-subset confirmed sufficient |
| 15 | ADR-0004 carry-forward decision recorded | resolve in this sub-issue's AAR | section-module pattern flagged for PRD-close ADR pass |

The audit table lands verbatim in the sub-issue's AAR. Any row that
comes back ⚠ or ✗ surfaces a flag in parent #38's `aar.md` and
blocks closure until resolved.

## Acceptance criteria

- [x] All fifteen audit rows above run; outcomes recorded in this
      sub-issue's AAR. Every row passes (✓) or carries an explicit
      flag explaining the deviation.
- [x] Cycle PRD open question #5 (composition-test depth) is
      resolved in this sub-issue's AAR with the reasoning. Default
      expectation: representative-subset confirmed sufficient,
      promotion to full-table snapshot deferred (per #41 AAR — no
      composition-order regression was missed by the subset).
- [x] ADR-0004 carry-forward note is recorded in this sub-issue's
      AAR for the cycle 03 PRD-close pass. The note states whether
      the section-module pattern joins ADR-0004 or warrants its own
      ADR — without making the call here. The PRD-close pass is
      the right scope for that comparison.
- [x] Parent #38's sibling `aar.md` lands at
      `context/cycles/03-config-deepening/issues/38-highlight-decomposition/aar.md`.
      It records the four-sub-issue arc (#39 → #40 → #41 → #42),
      summarizes the carry-forward from each sub-issue's AAR,
      confirms parent #38's flags list closes empty, and surfaces
      any cross-cutting carry-forward into the cycle 03 PRD close.
- [x] No source changes under `lua/colors/`, `lua/config/`,
      `lua/plugins/`, or `lua/utils/`. No new or modified files
      under `tests/`. Verified by `git status` showing only new
      files in
      `context/cycles/03-config-deepening/issues/38-highlight-decomposition/42-closing-decomposition-audit/`
      and the new
      `context/cycles/03-config-deepening/issues/38-highlight-decomposition/aar.md`.
- [x] `./tests/run` exits 0 — re-confirmed in this sub-issue, even
      though no source changed, to certify the closing state.
- [x] `PATH=/usr/bin:/bin ./tests/run` exits 0 — re-confirmed.
- [x] Parent #38 issue.md's twelve `[ ]` ACs are now `[x]`.
      Verified by reading `issue.md` after the audit and ticking
      each box (the ticks are part of this sub-issue's diff).

## Proposed tests

No new tests. The closing sub-issue's "tests" are the audit table
above, run as inspection commands. The full mini.test suite is
re-run as a closure-state certification step (AC #6 / #7), not as
new test additions.

If the audit surfaces a deviation that blocks closure, the response
is to surface a flag (in parent #38) and either resolve in this
sub-issue (if narrow) or open a remediation sub-issue. The
expectation, given #41's AAR, is no deviations.

## Affected artifacts

- **`context/cycles/03-config-deepening/issues/38-highlight-decomposition/42-closing-decomposition-audit/sub-issue.md`**
  — this file.
- **`context/cycles/03-config-deepening/issues/38-highlight-decomposition/42-closing-decomposition-audit/aar.md`**
  — new file. Records the audit-table outcomes, the open Q #5
  resolution, and the ADR-0004 carry-forward note.
- **`context/cycles/03-config-deepening/issues/38-highlight-decomposition/aar.md`**
  — new file. Parent #38's sibling AAR. Records the four-sub-issue
  arc, surfaces cross-cutting carry-forward into the cycle 03 PRD
  close, confirms flags list closes empty.
- **`context/cycles/03-config-deepening/issues/38-highlight-decomposition/issue.md`**
  — twelve `[ ]` ACs flipped to `[x]` after the audit confirms
  each is satisfied. No other edit.

No source files change. No test files change.

## Dependencies

- **Sub-issue #41 closure** — established the post-cycle structural
  state the audit verifies. The audit-table commands measure this
  state directly.
- **Sub-issue #40 closure** — section-partition decision recorded
  in its AAR (audit row 12 references it).
- **Sub-issue #39 closure** — merge-order decision recorded in its
  AAR (audit row 13 references it).
- **Cycle PRD open question #5** — composition-test-depth decision
  is resolved by this sub-issue's AAR.
- **Cycle 03 PRD close (downstream of this sub-issue)** — the
  ADR-0004 carry-forward note recorded here feeds into the
  PRD-close pass, where the section-module pattern is compared
  against the registrar (#22), subscribe (#33), os_theme (#35)
  family already carrying ADR-0004 candidacy.
- **No dependency on later parents.** Parent #38 is the last parent
  in cycle 03's resolved sequencing. After this sub-issue closes,
  the next work is the cycle 03 PRD-close pass, not a new parent.
