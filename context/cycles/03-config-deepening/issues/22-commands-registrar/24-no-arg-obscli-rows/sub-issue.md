# Sub-issue — No-arg ObsCLI commands migration batch

GitHub issue: #24. Second sub-issue of parent #22. The first
incremental migration sub-issue after #23's tracer slice. Migrates
the six remaining ObsCLI user commands that take zero arguments and
use the standard `(success, msg)` return envelope onto
`commands.register`. Re-uses the spec-row schema closed in #23
without introducing new shape decisions. Leaves the `nargs`/`complete`
forwards, the interactive `vim.fn.input` shape, the Solarized
void-return shape, and the WordCount commands for subsequent
sub-issues.

## Description

Migrate the six no-arg ObsCLI user commands in
`lua/config/commands.lua` from their inline
`vim.api.nvim_create_user_command(..., function() ... end, ...)`
shape onto `commands.register({ ... })` spec rows. The six
commands and their leaf functions on `utils.obsidian_cli`:

| Command | Leaf function |
| --- | --- |
| `ObsCLITaskToggle` | `toggle_task_from_quickfix()` |
| `ObsCLIOrphans` | `orphans_to_quickfix()` |
| `ObsCLIDeadends` | `deadends_to_quickfix()` |
| `ObsCLIUnresolved` | `unresolved_to_quickfix()` |
| `ObsCLIHistory` | `history_list_current()` |
| `ObsCLIBookmarks` | `bookmarks_list_verbose()` |

All six leaves take zero arguments and return `(success, msg)`. Each
registers as a spec row with required keys `name`, `desc`, `module`,
`fn` only — no `args`, no `on_load_error` override (the default
`"Failed to load utils.obsidian_cli"` is the same string the inline
blocks use). This is the exact `ObsCLITasks` shape from #23 minus the
`args` key.

`commands.lua` retains its current section-comment structure and
ordering; only the six command blocks themselves change shape. The
remaining 11 inline commands (the three `Solarized*`, the four
`nargs`-bearing `ObsCLI*`, the two WordCount commands, plus
`ObsCLISearchContext` and `ObsCLIBookmarkAdd`) stay byte-for-byte
unchanged. They migrate in subsequent sub-issues, grouped by the
shape decisions they introduce.

No new specs are added. The registrar's behavior is fully covered by
`tests/config/commands_registrar_spec.lua` from #23; this sub-issue
exercises the same code path with six more rows of input. A smoke
check — invoking each migrated command in a live Neovim session and
confirming observable behavior matches pre-migration — runs once
during implementation and is recorded in the AAR. Not a committed
spec.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `commands.register` | In-process (owned, this cycle) | Already covered by `tests/config/commands_registrar_spec.lua` from #23. The six new spec rows exercise the same shape the tracer locked in; no new registrar behavior is introduced. |
| `utils.obsidian_cli` (six leaf fns above) | In-process (consumer-side, owned) | Public surface unchanged from cycle 02 closure (parent #13). Migration is pass-through. Spec coverage of the leaves themselves is cycle 02's responsibility. |
| `vim.api.nvim_create_user_command` | In-process (Neovim API) | Reached via `commands.register` only. No direct call from `commands.lua` for the six migrated rows. |
| `vim.notify` | In-process (Neovim API) | Reached via `commands.register` only. |
| `mini.test` | In-process (test runner) | No new specs. Existing suite re-runs to confirm green. |

No new seam introduced. No new test surface needed.

## Interface design

This sub-issue uses the spec-row schema closed in #23 unchanged. The
shape, for each of the six rows, is:

```lua
register({
  name = "<UserCommandName>",
  desc = "<one-line description preserved verbatim from inline block>",
  module = "utils.obsidian_cli",
  fn = "<leaf function name>",
})
```

No new keys. No `args` (leaves take zero arguments). No
`on_load_error` override (default matches the inline blocks'
`"Failed to load utils.obsidian_cli"` string).

Two structural alternatives for *how* the six rows live in
`commands.lua` were considered.

### Alternative A — Six explicit `register({ ... })` calls

Each row is its own statement, in the same shape as the migrated
`ObsCLITasks` row from #23. The file reads as a flat sequence of
registration statements interleaved with section comments:

```lua
register({ name = "ObsCLITasks",       desc = "...", module = "utils.obsidian_cli", fn = "tasks_to_quickfix",
           args = function(_) return { { only_todo = true } } end })

register({ name = "ObsCLITaskToggle",  desc = "...", module = "utils.obsidian_cli", fn = "toggle_task_from_quickfix" })

register({ name = "ObsCLIOrphans",     desc = "...", module = "utils.obsidian_cli", fn = "orphans_to_quickfix" })
-- etc.
```

### Alternative B — Single loop over a local spec table

```lua
for _, spec in ipairs({
  { name = "ObsCLITaskToggle", desc = "...", module = "utils.obsidian_cli", fn = "toggle_task_from_quickfix" },
  { name = "ObsCLIOrphans",    desc = "...", module = "utils.obsidian_cli", fn = "orphans_to_quickfix" },
  -- ...
}) do
  register(spec)
end
```

Saves ~6 occurrences of `register(` and the trailing `)`. Reorders
the file's reading rhythm: a maintainer auditing user-command surface
now finds them inside a literal table inside a loop, not as
top-level statements.

### Comparison

- **Leverage.** A is the precedent #23 set for `ObsCLITasks`. Mixing
  A and B in the same file would create two registration shapes the
  closing sub-issue (Candidate F) has to reconcile. B alone would
  require backing out the precedent #23 just established.
- **Locality.** A keeps each command as a top-level statement —
  `grep -n 'name = "ObsCLI'` finds one match per command on its own
  line. B nests the matches inside a literal table, which still
  greps but reads as data inside a control structure rather than as
  top-level configuration.
- **Testability.** Equivalent. Both shapes feed the same
  `commands.register`; the registrar is the test seam, not the
  iteration shape.
- **Future-proofing.** Whether `commands.lua` reads as a declarative
  spine — story 3 of the sub-PRD, the question Candidate F gates on
  — is decided at parent #22 closure. A keeps the file's surface
  identical row-to-row, which is the cleanest input to that closure
  decision. If the closure decides B is what makes the file scannable,
  it can flip the whole file then with full information from all 18
  migrations.

### Chosen: A

Reason for rejecting B: B optimizes for line count at the cost of
mid-cycle precedent reversal and a second registration shape inside
the same file. The closing sub-issue is the right place to evaluate
whether to flatten the file into a single iterated table — with all
17 migrations in hand, not just six. Until then, every new row mirrors
the `ObsCLITasks` precedent #23 set.

### Entry points, inputs, outputs, invariants, error modes

No interface changes. The registrar's interface from #23 is the
contract. Each migrated row is one application of that contract.

- **Invariant carry-forward from #23:** `commands.register` calls
  `nvim_create_user_command` exactly once per row. The callback never
  throws. The four return-shape branches (load failure, leaf failure,
  leaf success with message, leaf success silent) behave identically
  to the inline blocks they replace.
- **Behavioral parity check:** for each of the six commands, the
  pre-migration inline block and the post-migration spec row produce
  the same observable behavior — same `nvim_create_user_command`
  name, same `desc`, same `pcall(require)` failure message at ERROR
  level, same `(success, msg)` envelope handling. Verified by
  inspection against pre-cycle `git show` plus a live smoke check
  recorded in the AAR.

## Acceptance criteria

- [ ] Each of the six commands — `ObsCLITaskToggle`, `ObsCLIOrphans`,
      `ObsCLIDeadends`, `ObsCLIUnresolved`, `ObsCLIHistory`,
      `ObsCLIBookmarks` — is registered through `commands.register`
      with the spec row shape `{ name, desc, module = "utils.obsidian_cli", fn }`.
- [ ] Each migrated row preserves its `desc` string verbatim from the
      pre-migration inline block. Verified by diffing pre-cycle
      `git show HEAD~:lua/config/commands.lua` against the new
      `commands.lua` for those six descriptions.
- [ ] After migration, `lua/config/commands.lua` contains zero direct
      calls to `vim.api.nvim_create_user_command` for any of the six
      migrated commands. Verified by
      `grep -n 'nvim_create_user_command(\"\(ObsCLITaskToggle\|ObsCLIOrphans\|ObsCLIDeadends\|ObsCLIUnresolved\|ObsCLIHistory\|ObsCLIBookmarks\)\"' lua/config/commands.lua`
      returning zero matches.
- [ ] After migration, `lua/config/commands.lua` contains zero
      occurrences of the inline `pcall(require, "utils.obsidian_cli")`
      → call → `vim.notify` block for any of the six migrated
      commands. (Two such blocks remain — for `ObsCLISearchContext`
      and `ObsCLIBookmarkAdd` — and migrate in later sub-issues.)
- [ ] The 11 commands not migrated in this sub-issue —
      `SolarizedToggle`, `SolarizedDark`, `SolarizedLight`,
      `ObsCLISearchContext`, `ObsCLIHistoryRead`, `ObsCLIDiffFrom`,
      `ObsCLIOutline`, `ObsCLIBacklinks`, `WordCount`,
      `ObsCLIWordCount`, `ObsCLIBookmarkAdd` — are byte-for-byte
      unchanged from pre-sub-issue state. Verified by `git diff` on
      `commands.lua` showing edits only inside the six migrated
      blocks (plus possible whitespace/section-comment adjustments
      adjacent to them).
- [ ] No edits to `lua/config/commands_registrar.lua`. The registrar
      from #23 is consumed unchanged.
- [ ] No edits to `lua/utils/obsidian_cli/` (any file). The leaf
      module's public surface is consumed unchanged.
- [ ] No new specs added; no specs removed. The existing
      `tests/config/commands_registrar_spec.lua` from #23 covers the
      registrar's behavior; this sub-issue's migrations are pass-through.
- [ ] `./tests/run` exits 0 on the whole suite — including all cycle
      01 specs, cycle 02 specs, and the registrar spec from #23.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `obsidian` and `codesign` absent from `$PATH`).
- [ ] Live smoke check — recorded in the AAR, not a committed spec —
      invokes each of the six migrated commands inside Neovim and
      confirms observable behavior matches pre-migration: each opens
      its quickfix list / scratch buffer, or surfaces the same
      ERROR-level notify on failure. The check runs once during
      implementation; the AAR records the result and any deviations.
- [ ] `wc -l lua/config/commands.lua` is strictly less than the
      pre-sub-issue line count. (Parent #22's <120-line target is not
      reached by this sub-issue alone — that target gates on closure
      of all 17 remaining migrations plus the closing sub-issue.)
- [ ] No reaching into local functions or monkey-patching internals.
      No new specs are added, but the carry-forward acceptance
      criterion from cycles 01 and 02 still binds: any test edits
      in this sub-issue (including none, the expected case) respect it.
- [ ] AAR records: the line-count delta on `commands.lua`, the
      live-smoke-check result for each of the six commands, and any
      flags surfaced for subsequent migration sub-issues to inherit.

## Proposed tests

No new specs are added by this sub-issue. The existing registrar
spec from #23 already covers every observable branch of the
registrar's callback shape (registration, load failure, leaf failure,
leaf success with non-empty message, leaf success with empty/nil
message). The six migrations exercise the same code paths with new
input rows; that exercise is implicit in the migrated `commands.lua`
sourcing during the test bootstrap.

A deliberate-failure verification runs once during implementation:
swap one of the six `fn` values to a non-existent leaf key (e.g.,
`fn = "orphans_does_not_exist"`), confirm that invoking the
corresponding command in a live Neovim session surfaces the
ERROR-level notify the registrar's leaf-call branch produces (note:
the failure mode here is a `nil` indexed call, which the registrar's
current shape does *not* explicitly guard — so the deliberate-failure
verification doubles as a flag-check: if the notify path swallows it
gracefully, no flag; if it surfaces an ugly Lua error, that is a flag
for a subsequent registrar-hardening sub-issue). Revert. Record in
the AAR.

If the deliberate-failure verification surfaces the latter, the AAR
records a flag for parent #22, *not* a fix in this sub-issue —
hardening the registrar against missing-key calls is a registrar-shape
decision, not a row-migration decision, and belongs to whichever
sub-issue takes it on under parent #22's scope.

## Affected artifacts

- Edited: `lua/config/commands.lua` — the six command blocks for
  `ObsCLITaskToggle`, `ObsCLIOrphans`, `ObsCLIDeadends`,
  `ObsCLIUnresolved`, `ObsCLIHistory`, `ObsCLIBookmarks` are replaced
  by `commands.register({ ... })` spec rows in place.
- Unchanged: `lua/config/commands_registrar.lua`.
- Unchanged: `tests/config/commands_registrar_spec.lua` (and every
  other spec file).
- Unchanged: `lua/utils/obsidian_cli/` (any file).
- Unchanged: `lua/colors/solarized.lua`.
- Unchanged: `lua/utils/wordcount.lua`.
- Unchanged: `tests/init.lua`, `tests/run`.
- New: this sub-issue's `aar.md` on close.

## Dependencies

- **#23 closure** — `commands.register` exists at
  `lua/config/commands_registrar.lua` with the spec-row schema this
  sub-issue's six rows use unchanged. Already closed.
- **Cycle 02 closure (parent #13)** —
  `lua/utils/obsidian_cli/init.lua` exposes
  `toggle_task_from_quickfix`, `orphans_to_quickfix`,
  `deadends_to_quickfix`, `unresolved_to_quickfix`,
  `history_list_current`, `bookmarks_list_verbose` with the
  `(success, msg)` envelope and zero-argument signatures. Verified by
  inspection at the migration call sites.
- **Cycle 01 closure** — `mini.test` harness at `./tests/run`. The
  existing registrar spec from #23 re-runs green to confirm no
  regression.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `24-no-arg-obscli-rows` tracks GitHub
  issue #24.
- No dependency on any other cycle 03 sub-issue beyond #23.

## Out of scope (deferred to subsequent sub-issues of parent #22)

- Migration of `ObsCLISearchContext`. It uses `vim.fn.input` to
  prompt for a query and surfaces a WARN-level early return on empty
  input. Migrating it requires a spec-row shape decision: extend
  `args` to support early-return-with-warn, add an `on_invalid_args`
  hook, or wrap the prompt-and-validate inside `args` and let it
  return a sentinel that the registrar interprets. That decision
  belongs to whichever sub-issue takes the interactive-prompt shape
  on first.
- Migration of `ObsCLIHistoryRead`, `ObsCLIDiffFrom`, `ObsCLIOutline`,
  `ObsCLIBacklinks`. They all carry `nargs = "?"` (or `"*"`) and need
  the registrar to forward `nargs` to `nvim_create_user_command`'s
  opts. Forwarding lands in the sub-issue that migrates the first
  one. Three of them additionally fall back to `vim.fn.input` on
  empty args, which intersects with the `ObsCLISearchContext`
  decision above.
- Migration of `ObsCLIBookmarkAdd` and `ObsCLIWordCount`. Both carry
  `nargs = "*"` and a custom `args` parser shape (the
  `ObsCLIBookmarkAdd` title prompt and the `ObsCLIWordCount`
  trailing-mode-token parsing). They migrate after the
  `nargs`-forwarding decision lands.
- Migration of the three `Solarized*` commands. Their leaves
  (`set_theme`, `toggle`) do not return `(success, msg)`. The shape
  used to model them — variant spec, separate `register_void`, or
  thin `(true, "")` adapter — is the parent #22 deferred decision on
  void returns.
- Migration of `WordCount`. Carries `range = true` (forwarded to
  opts) and synthesizes its own notify message from leaf return — a
  third shape variant. Lands when range-forwarding is decided.
- Hardening the registrar against missing-`fn` calls (the deliberate-
  failure verification's edge case above). If surfaced as a flag in
  this sub-issue's AAR, it is a separate sub-issue under parent #22 —
  not folded in here.
- Candidate F (domain split of `commands.lua`) decision. Closing
  sub-issue of parent #22.
- ADR-0004 candidacy for the registrar pattern. Per cycle PRD open
  question 4, deferred until at least one more seam (Candidate B or
  D) is in place.
