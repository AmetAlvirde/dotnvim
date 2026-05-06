# Sub-issue — Parent 22 closure: contract verification, AC reconciliation, deferred-decision recording

GitHub issue: #28. Sixth and closing sub-issue of parent #22, after
#23's tracer, #24's no-arg ObsCLI batch, #25's `nargs`-bearing ObsCLI
batch, #26's Solarized void-return batch, and #27's Search and
WordCount migration. After this sub-issue, every user command in
`lua/config/commands.lua` is registered through the registrar, every
parent-#22 acceptance criterion is either verified-and-checked or
amended-with-recorded-reason, and parent #22 closes.

This sub-issue carries no behavior change. The registrar's shape and
`commands.lua`'s spec-row population are frozen at #27's close; the
work here is verification, AC reconciliation, and recording two
resolved-through-implementation decisions parent #22 deferred to its
closing sub-issue:

1. **Candidate F decision** — domain split of `commands.lua` by
   `solarized` / `obsidian_cli` / `wordcount`. Resolved as **skip**
   with one-sentence reason recorded in parent `issue.md`. Reason:
   the post-#27 `commands.lua` is a flat list of `register({ ... })`
   spec rows under preserved section comments, scannable as one
   declarative file; no second pressure point (a 19th command, a
   second registrar consumer, real ergonomic friction) has surfaced
   to justify a split. Deferring keeps locality high — every
   command's full registration lives in one file — and avoids
   inventing a domain split before the domains themselves push back.

2. **ADR-0004 candidacy** — whether the registrar pattern earns a
   committed ADR now. Resolved as **defer to cycle 03 close**.
   Reason: the registrar is currently a single-consumer pattern;
   ADRs benefit from a second pressure point. Candidates B
   (`autocmds.subscribe`) and D (autocmd binding) will inherit the
   same fake-the-API test pattern this parent established. After at
   least one of them lands, the pattern's ADR-worthy invariants are
   visible from two seams, not one. The cycle-close decision then
   has the leverage to write one ADR covering the family rather
   than a registrar-specific ADR that would need superseding.

Two further reconciliations the parent issue requires before close:

3. **Strict-grep AC scope amendment.** The grep AC (parent
   `issue.md` lines 13–17) currently reads
   `grep -rn 'nvim_create_user_command' lua/`. `lua/plugins/lualine.lua`
   contains a `LualineRefresh` user command — a plugin-internal
   closure that calls `setup_lualine()` and redraws — registered
   inside the plugin spec's `config` function. It is not one of
   the 18 commands enumerated in parent `issue.md` lines 26–34, has
   no leaf module to `pcall(require)`, no `(success, msg)` envelope,
   and no `vim.notify` shape. Forcing it through `commands.register`
   would require a closure-only spec kind for one one-off — the
   same kind of premature-abstraction pressure rejected in #26
   (Alternative C adapters) and #27 (parallel discriminators). The
   AC is amended to scope the grep to `lua/config/`, the directory
   the contract owns; plugin-spec internal commands under
   `lua/plugins/` are recorded as out-of-contract.

4. **Line-budget AC removal.** Parent `issue.md` lines 24–25 read
   `wc -l lua/config/commands.lua` returns under 120 lines (down
   from 366). *(Cycle PRD success metric #2.)*. This AC is dropped:
   line counts do not shape the contract. The AC's structural
   intent — "`commands.lua` becomes a list of spec rows, each fed
   to `commands.register`. The per-command `pcall(require, ...)` →
   call → `vim.notify` block is gone." — is already enforced by
   the AC at lines 18–23, which is preserved. The cycle PRD success
   metric is updated to record the structural outcome (every command
   registered through `commands.register`; zero direct
   `nvim_create_user_command` and `pcall(require, "utils.…")` calls
   in `commands.lua`) without the line-count threshold.

## Description

Verification, recording, and AC reconciliation. No edits to
`lua/config/commands.lua`, `lua/config/commands_registrar.lua`,
`lua/utils/`, `lua/colors/`, or any test file unless verification
fails — in which case the failure becomes a flag escalated to parent
#22, not patched silently here.

The work, in order:

1. **Run the contract verifications recorded in parent `issue.md`'s
   acceptance criteria** — the strict grep (scoped per amendment 3
   above), the no-edit `git diff` for `lua/utils/obsidian_cli/`,
   `lua/utils/wordcount.lua`, `lua/colors/solarized.lua`, the full
   `./tests/run`, and `PATH=/usr/bin:/bin ./tests/run`. Record each
   command, its output, and its pass/fail in this sub-issue's AAR.

2. **Amend parent `issue.md`** to (a) scope the strict grep AC to
   `lua/config/` with a one-line note recording `LualineRefresh` as
   out-of-contract, (b) delete the line-budget AC, (c) record the
   Candidate F skip decision and reason in the deferred-decision
   checkbox, (d) record the ADR-0004 defer-to-cycle-close decision
   adjacent to or within the same checkbox.

3. **Update the cycle PRD's success-metric language** to drop the
   line-count threshold and replace it with the structural outcome.
   Scope is the success-metric line only; user stories, scope,
   non-goals, and dependencies are not edited.

4. **Sweep the parent `issue.md` checkbox state** — every AC that
   verification passes is checked; every AC amended in step 2 is
   checked against its amended form; flags surfaced during
   verification are recorded in the parent's "Flags" section, not
   silently absorbed.

5. **Add a one-line guard comment to `lua/plugins/lualine.lua`**
   adjacent to the `nvim_create_user_command` call, recording that
   `LualineRefresh` is plugin-internal and out of `commands.register`'s
   contract. Optional — see Decision 3 below; chosen alternative
   determines whether this step lands.

If any verification step fails — `git diff` shows an unexpected edit,
the suite goes red, the strict grep returns matches outside
`commands_registrar.lua`, the `PATH`-stripped suite fails — the
failure is flagged and the sub-issue does not close until the flag
is resolved. Resolution of an unexpected `git diff` flag is a
separate code change scoped to undoing the unintended edit, not
reshaping the registrar.

## Dependency classification

| Dependency | Category | Verification strategy |
| --- | --- | --- |
| `commands.register` | In-process (owned, this cycle, frozen) | Not edited. Verified in-place via the parent's strict grep (scoped to `lua/config/`). |
| `lua/config/commands.lua` | In-process (owned, this cycle, frozen) | Not edited. Verified by the strict grep returning matches only inside `commands_registrar.lua`, and by `grep -n 'pcall(require, "utils\.\(obsidian_cli\|wordcount\)")' lua/config/commands.lua` returning zero matches. |
| `lua/utils/obsidian_cli/` | In-process (consumer-side, frozen by parent constraint 2) | Verified by `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` being empty. |
| `lua/utils/wordcount.lua` | In-process (consumer-side, frozen by parent constraint 2) | Same shape: `git diff <cycle-base>..HEAD -- lua/utils/wordcount.lua` empty. |
| `lua/colors/solarized.lua` | In-process (consumer-side, public-surface frozen by parent constraint 2) | Same shape: `git diff <cycle-base>..HEAD -- lua/colors/solarized.lua` empty. |
| `lua/plugins/lualine.lua` | In-process (plugin-spec owned, out-of-contract for parent #22) | Optionally edited to add a one-line guard comment (Decision 3 below). Otherwise unchanged. |
| `mini.test` | In-process (test runner) | Not edited. The full suite runs to verify the suite-green AC and the `PATH`-stripped AC. |
| `git` | Out-of-process (CLI) | Used for the no-edit `git diff` verifications. Read-only. |

No new seam introduced. No spec cases added or modified.

## Interface design

This sub-issue makes three small decisions. Two are recording
decisions (Candidate F, ADR-0004) already framed in the header
block; the third is whether to add a guard comment in
`lua/plugins/lualine.lua`. Each is independently designed below
with at least two alternatives and a chosen-with-reason.

---

### Decision 1 — Candidate F (domain split of `commands.lua`)

#### Alternative 1A — Skip, defer until pressure point materialises

Record in parent `issue.md` that Candidate F is skipped for cycle
03. One sentence captures the reason: post-#27 `commands.lua` is a
flat list of spec rows under preserved section comments, scannable
as one declarative file; no second pressure point (19th command,
second registrar consumer, real ergonomic friction) has surfaced.
The skip is a decision, not an oversight.

#### Alternative 1B — Land the split now

Add a closing implementation sub-issue (#29 onward) that splits
`commands.lua` into per-domain files (`commands_solarized.lua`,
`commands_obsidian_cli.lua`, `commands_wordcount.lua`) and a
top-level `commands.lua` that requires them all. Each file holds
its domain's `register({ ... })` calls.

#### Comparison

- **Locality.** 1A keeps every command's registration in one file —
  one place to read the full surface. 1B trades single-file scan
  for per-domain isolation; readers who want "what commands does
  this config define?" must read three files.
- **Leverage.** 1A pays nothing now; if a 19th command or a second
  registrar consumer surfaces in a future cycle, that's when the
  split's leverage is real. 1B pays the cost (three new files,
  three new requires, three sets of imports) for capacity that
  isn't being used.
- **Process discipline.** Parent `issue.md`'s deferred-decision AC
  (lines 73–76) explicitly accommodates skip-with-reason as a valid
  resolution. Choosing skip is the contract honoring the option it
  named, not punting.
- **Reversibility.** Both directions are reversible — 1B is a pure
  reorganisation of `register({ ... })` calls; 1A leaves the
  reorganisation available when needed.

#### Chosen — 1A

Reason for rejecting 1B: no pressure point in cycle 03 justifies
the split. The cycle PRD's Candidate F was framed as "if the
registered list is no longer scannable as one file" — after #27,
the file remains scannable. Splitting before pressure point means
inventing a domain partition that real consumers haven't asked for.

---

### Decision 2 — ADR-0004 candidacy for the registrar pattern

#### Alternative 2A — Defer to cycle 03 close

Do not write ADR-0004 in this sub-issue. Record the deferral
reason: the registrar is currently a single-consumer pattern;
Candidates B (`autocmds.subscribe`) and D (autocmd binding) inherit
its fake-the-API test pattern. After at least one of them lands,
the pattern's ADR-worthy invariants are visible from two seams,
not one — and the cycle-close decision can write one ADR covering
the family rather than a registrar-specific ADR that would need
superseding once B or D landed.

#### Alternative 2B — Write ADR-0004 now, narrowly scoped to the registrar

Land ADR-0004 in this sub-issue. Scope: the registrar pattern as
proven across #23–#27 (spec-row schema, `kind`-discriminated
branches, abort-tuple from `args`, fake-the-API test seam). Mark
the ADR as registrar-specific with a forward note that B/D may
generalise it.

#### Comparison

- **Pressure point.** 2A waits for two pressure points (registrar
  + at least one of B/D); 2B records one. ADRs that capture
  decisions across two pressure points carry more leverage and
  are less likely to need superseding.
- **Scope drift risk.** 2B requires deciding the ADR's exact
  scope now: does it cover only the registrar, or a generic
  fake-the-API-seam pattern? Either choice constrains B/D's
  future ADR work in ways that are hard to predict before B/D
  exist.
- **Process discipline.** Cycle PRD open question 4 framed
  ADR-0004 as a cycle-close decision, contingent on at least one
  more seam. 2A honors that framing; 2B preempts it.

#### Chosen — 2A

Reason for rejecting 2B: writing the ADR before a second seam is
visible commits to a scope that may need revisiting once B or D
lands. The cost of waiting is one cycle close; the cost of an
ADR that needs superseding within one cycle is higher.

---

### Decision 3 — Lualine guard comment in `lua/plugins/lualine.lua`

The strict grep AC is amended to scope to `lua/config/`. Anyone
running the literal old grep (`grep -rn 'nvim_create_user_command' lua/`)
will see the `LualineRefresh` match and may wonder whether it's a
contract violation. A guard comment makes the out-of-contract status
visible without requiring the reader to consult `issue.md`.

#### Alternative 3A — Add a one-line guard comment

```lua
-- Plugin-internal user command (out of commands.register's contract);
-- see context/cycles/03-config-deepening/issues/22-commands-registrar/issue.md.
vim.api.nvim_create_user_command('LualineRefresh', function()
```

One line, one path reference, no behavior change.

#### Alternative 3B — No guard comment; rely on `issue.md` and AAR

Leave `lua/plugins/lualine.lua` unchanged. The AC amendment in
`issue.md` and the recording in this sub-issue's AAR are the
canonical record. A reader running the literal old grep is
expected to read `issue.md` next.

#### Comparison

- **Locality.** 3A puts the explanation next to the code that
  raises the question. 3B puts it in the contract document the
  reader has to know to consult.
- **Cost.** 3A is one line and one cross-reference. 3B is zero.
- **Drift.** 3A's path reference is a maintenance dependency:
  if `issue.md`'s path changes, the comment goes stale. The
  registrar/cycle layout has been stable across #23–#27 and
  ADR-0002 fixes the folder slug, so the drift risk is low.

#### Chosen — 3A

Reason for rejecting 3B: the guard comment is one line of
locality for a real reader interaction (the literal grep). The
path-drift risk is low under ADR-0002's slug discipline. The
locality wins.

## Acceptance criteria

- [ ] Strict grep, scoped per amendment 3:
      `grep -rn 'nvim_create_user_command' lua/config/` returns
      matches only inside `lua/config/commands_registrar.lua`.
      Output recorded verbatim in this sub-issue's AAR.
- [ ] Plugin-spec carve-out: `grep -rn 'nvim_create_user_command' lua/plugins/`
      returns the single match in `lua/plugins/lualine.lua` for
      `LualineRefresh` and no others. Output recorded in the AAR.
      If a second match surfaces, it becomes a flag — not a fix
      in this sub-issue.
- [ ] No-`pcall(require)` check on `commands.lua`:
      `grep -n 'pcall(require, "utils\.\(obsidian_cli\|wordcount\)")' lua/config/commands.lua`
      returns zero matches.
- [ ] Git-diff verification for `lua/utils/obsidian_cli/`:
      `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` is
      empty. The cycle base commit (the commit cycle 03 forked
      from) is identified in the AAR; verification command and
      output are recorded.
- [ ] Git-diff verification for `lua/utils/wordcount.lua`:
      `git diff <cycle-base>..HEAD -- lua/utils/wordcount.lua` is
      empty.
- [ ] Git-diff verification for `lua/colors/solarized.lua`:
      `git diff <cycle-base>..HEAD -- lua/colors/solarized.lua` is
      empty.
- [ ] `./tests/run` exits 0 on the whole suite. Final case count
      and any cycle-01 / cycle-02 / cycle-03 spec-file counts
      recorded in the AAR.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `obsidian` and `codesign` absent from
      `$PATH`). Recorded in the AAR.
- [ ] Parent `issue.md` is amended to:
      1. Scope the strict grep AC (lines 13–17) to `lua/config/`,
         with a one-line note recording `LualineRefresh` as
         out-of-contract;
      2. Delete the line-budget AC (lines 24–25) entirely. No
         replacement AC; the structural-intent AC at lines
         18–23 already enforces the registrar-list shape.
      3. Replace the Candidate F deferred-decision checkbox
         (lines 73–76) with a checked entry recording the skip
         decision and the one-sentence reason from this
         sub-issue's header.
      4. Add an ADR-0004 deferral note adjacent to the Candidate F
         entry (or as a sibling resolved-through-implementation
         entry), recording the defer-to-cycle-close decision and
         the one-sentence reason from this sub-issue's header.
- [ ] All other parent `issue.md` checkboxes (registrar interface,
      `commands.lua` reshape, 18 commands preserved, registrar
      spec coverage, no-edits constraints, suite green,
      `PATH`-stripped suite green, no-monkey-patching) are checked
      against their verification command's recorded output. Every
      checked box has a verification line in the AAR mapping
      checkbox to evidence.
- [ ] Cycle PRD success-metric language is updated: the line-count
      threshold ("`commands.lua` ≤ 120 lines, down from 366") is
      replaced with the structural outcome ("every user command in
      `commands.lua` is registered through `commands.register`;
      zero direct `nvim_create_user_command` and zero direct
      `pcall(require, "utils.…")` calls remain in `commands.lua`").
      Scope is the success-metric line only; the cycle PRD's user
      stories, scope, non-goals, and dependencies are not edited.
- [ ] `lua/plugins/lualine.lua` gains a one-line guard comment
      immediately above the `vim.api.nvim_create_user_command(
      'LualineRefresh', ...)` call, identifying the command as
      plugin-internal / out-of-contract and pointing at parent
      `issue.md`. No behavior change. (Per Decision 3.)
- [ ] No edits to `lua/config/commands.lua`,
      `lua/config/commands_registrar.lua`,
      `tests/config/commands_registrar_spec.lua`, or any other
      test file. Verified by `git diff` showing no changes to
      those paths.
- [ ] AAR records: every verification command and its output
      verbatim; each parent-`issue.md` checkbox with the AC text
      and the evidence line; the resolution of Candidate F,
      ADR-0004, and the Lualine guard-comment decisions; any
      flags surfaced during verification (each flag tagged as
      "carry forward to parent #22" or "in-scope inline fix" with
      reason); the closing recommendation for parent #22 (close,
      or hold open with named flag).

## Proposed tests

No new spec cases. No edits to existing spec cases.

The `./tests/run` and `PATH=/usr/bin:/bin ./tests/run` invocations
are AC verifications, not new tests. Their pass/fail is the
existing suite's pass/fail; this sub-issue adds no assertions.

A deliberate-failure verification runs once:

1. Temporarily mutate `lua/plugins/lualine.lua` so its
   `nvim_create_user_command` call lives at a path that the
   amended grep covers (e.g. copy the call into
   `lua/config/scratch.lua`). Re-run the strict grep. Confirm the
   grep surfaces the new match, demonstrating that the amended
   AC actually enforces its scope. Revert.

The verification confirms that "scope to `lua/config/`" isn't
silently equivalent to "find nothing"; it actively excludes
`lua/plugins/` and includes `lua/config/`. Recorded in the AAR.

## Affected artifacts

- Edited: parent `issue.md` — strict-grep AC scope amendment,
  line-budget AC deletion, Candidate F decision recording,
  ADR-0004 deferral recording, checkbox sweep against recorded
  evidence.
- Edited: `context/cycles/03-config-deepening/prd.md` — cycle PRD
  success metric replaced with structural outcome (one line; user
  stories / scope / non-goals / dependencies unchanged).
- Edited: `lua/plugins/lualine.lua` — one-line guard comment
  immediately above the `LualineRefresh` registration. No
  behavior change.
- Unchanged: `lua/config/commands.lua`.
- Unchanged: `lua/config/commands_registrar.lua`.
- Unchanged: `lua/utils/obsidian_cli/` (any file).
- Unchanged: `lua/utils/wordcount.lua`.
- Unchanged: `lua/colors/solarized.lua`.
- Unchanged: `tests/config/commands_registrar_spec.lua` and all
  other specs.
- Unchanged: `tests/init.lua`, `tests/run`.
- New: this sub-issue's `aar.md` on close.

## Dependencies

- **#23 closure** — registrar location, schema baseline. Already
  closed.
- **#24 closure** — no-arg ObsCLI batch migration pattern. Already
  closed.
- **#25 closure** — `nargs` forwarding pattern. Already closed.
- **#26 closure** — `kind`-discriminated branch pattern (`void`).
  Already closed.
- **#27 closure** — full registrar surface (default envelope +
  `void` + `synthesized_notify` + abort + `nargs` + `range`). All
  18 user commands migrated. Already closed.
- **Cycle 01 closure** — `mini.test` harness at `./tests/run`.
- **Cycle 02 closure (parent #13)** — `lua/utils/obsidian_cli/`
  public surface frozen at the registration target. Already
  closed.
- **ADR-0001** — `mini.test` as the test runner. Determines the
  `./tests/run` interface used in verification.
- **ADR-0002** — sequential GitHub issue numbering. This
  sub-issue is #28; folder slug is `28-parent-22-closure`.
- No dependency on any other cycle 03 parent. Parents B
  (autocmds.subscribe), C (config slot wiring), D (autocmd
  binding) inherit this parent's test pattern but do not block
  this sub-issue.

## Out of scope (for this sub-issue or for future cycles)

- **Migrating `LualineRefresh` through `commands.register`.** The
  registrar's design is leaf-module dispatch; `LualineRefresh` is
  a closure over plugin-internal state with no leaf module to
  require. Forcing it through the registrar requires inventing a
  closure-only spec kind for one one-off — premature abstraction.
  If a future cycle adds a second plugin-internal closure command
  with a real abstraction pressure, that's when the kind earns its
  branch.
- **Splitting `commands.lua` by domain (Candidate F).** Resolved
  here as skip-until-pressure-point. Lands when a 19th command,
  a second registrar consumer, or real scannability friction
  surfaces — not before.
- **Writing ADR-0004 for the registrar pattern.** Resolved here
  as defer-to-cycle-close. Re-enters scope at cycle 03's close,
  after at least one of Candidates B / D has demonstrated the
  fake-the-API test pattern from a second seam.
- **Hardening the registrar against missing-`fn` calls.** Carried
  forward from #24's AAR flag. Not in scope here. If the live
  smoke check during this sub-issue's verification surfaces it,
  it becomes a parent #22 flag, not a fix in this sub-issue.
- **`complete` and `bang` forwarding.** Carried forward from #25
  and #27. No consumer in cycle 03. Lands when one needs it.
- **Domain-language additions to `ubiquitous-language.md`.** No
  new domain terms introduced here. The terms used in this
  sub-issue (*verification*, *checkbox sweep*, *deferred-decision
  recording*) are process language, not domain.
- **Re-running parent #22's full-suite verification under
  alternative shells, OS configurations, or Neovim versions.**
  The contract specifies `./tests/run` and
  `PATH=/usr/bin:/bin ./tests/run` as the two suite invocations.
  Cross-platform / cross-version verification belongs to the
  cycle close, not this sub-issue.
- **Updating `context/refactor-backlog.md`.** Anything surfaced
  during verification that doesn't block parent #22's close but
  warrants future attention is recorded in the AAR's flags
  section, not in the refactor backlog. The backlog is curated
  at cycle close, not per sub-issue.
