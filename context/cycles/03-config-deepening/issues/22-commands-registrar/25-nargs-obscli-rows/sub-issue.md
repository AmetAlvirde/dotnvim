# Sub-issue — `nargs`-bearing ObsCLI commands migration batch

GitHub issue: #25. Third sub-issue of parent #22, after #23's tracer
and #24's no-arg batch. Migrates the five remaining ObsCLI user
commands that carry `nargs` (`?` or `*`) and the `(success, msg)`
return envelope onto `commands.register`. Introduces exactly one new
spec-row shape decision: `nargs` forwarding from the spec to
`nvim_create_user_command`'s opts. The `args` function continues to
carry whatever per-command argument logic the inline block currently
holds — including, for two of these commands, a `vim.fn.input`
fallback when `cmd_opts.args` is empty. That is a new *usage* pattern
of the `args` key, not a new spec-row shape decision; the registrar's
contract is unchanged for `args`.

## Description

Migrate five ObsCLI user commands in `lua/config/commands.lua` from
their inline `vim.api.nvim_create_user_command(..., function(opts)
... end, { nargs = ..., desc = ... })` shape onto
`commands.register({ ... })` spec rows:

| Command | Leaf function | `nargs` | `args` shape (post-migration) |
| --- | --- | --- | --- |
| `ObsCLIHistoryRead` | `history_read_current(v)` | `"?"` | reads `cmd_opts.args`; on empty, prompts via `vim.fn.input("History version to read (number): ")`; passes the string to the leaf |
| `ObsCLIDiffFrom` | `diff_current_from(v)` | `"?"` | reads `cmd_opts.args`; on empty, prompts via `vim.fn.input("Diff from local history version (number): ")`; passes the string to the leaf |
| `ObsCLIOutline` | `outline_current({ format = fmt })` | `"?"` | reads `cmd_opts.args`; defaults to `"tree"` when empty; wraps in `{ format = ... }` |
| `ObsCLIBacklinks` | `backlinks_counts_to_quickfix(path)` | `"?"` | reads `cmd_opts.args`; nils out empty-trimmed; passes the string-or-nil to the leaf |
| `ObsCLIBookmarkAdd` | `bookmark_add_current({ title = ... })` | `"*"` | reads `vim.trim(cmd_opts.args or "")`; wraps non-empty in `{ title = ... }`; nil otherwise |

All five leaves return `(success, msg)`. None require `complete`,
`range`, or `bang`. The new spec-row key — `nargs` — is forwarded
verbatim to `nvim_create_user_command`'s opts table.

Add `nargs` forwarding to `lua/config/commands_registrar.lua`. The
forward is whitelisted (only `nargs`, no other opts) — `complete`,
`range`, and `bang` stay deferred until a command needing them
migrates. The registrar's existing five callback branches (load
failure, leaf failure, leaf success silent, leaf success silent-nil,
leaf success with message) are unchanged.

Add one or two new cases to `tests/config/commands_registrar_spec.lua`
covering `nargs` forwarding: a spec row with `nargs = "?"` produces a
recorded `nvim_create_user_command` call whose `opts.nargs` equals
`"?"`; a spec row without `nargs` produces a recorded call whose
`opts.nargs` is `nil`. No new spec exercises `vim.fn.input`-from-
inside-`args` — that path is a usage pattern of the existing `args`
contract, already covered by the "args is invoked" coverage in
#23's spec.

`commands.lua` retains its current section-comment structure and
ordering; only the five command blocks themselves change shape. The
remaining 6 inline commands (the three `Solarized*`,
`ObsCLISearchContext`, `WordCount`, `ObsCLIWordCount`) stay byte-for-
byte unchanged. They migrate in subsequent sub-issues, grouped by
the shape decisions they introduce (void-return for `Solarized*`,
early-return-with-warn for `ObsCLISearchContext`, `range` forwarding
plus custom-notify for the WordCount pair).

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `commands.register` | In-process (owned, this cycle) | Edited in this sub-issue. The added `nargs` forwarding is covered by new spec cases. The unchanged callback-branch behavior is covered by the seven spec cases inherited from #23. |
| `utils.obsidian_cli` (five leaf fns above) | In-process (consumer-side, owned) | Public surface unchanged from cycle 02 closure (parent #13). Migration is pass-through. |
| `vim.api.nvim_create_user_command` | In-process (Neovim API) | Reached via `commands.register` only. The new `opts.nargs` field is asserted on the recorded call shape via the existing `pre_case`/`post_case` swap pattern. |
| `vim.notify` | In-process (Neovim API) | Reached via `commands.register` only. Behavior unchanged. |
| `vim.fn.input` | In-process (Neovim API, used inside `args` for two rows) | Not stubbed in the registrar spec — the registrar has no opinion on `args` internals. The two `args` functions that call `vim.fn.input` are exercised at runtime by the live smoke check, not by spec. Deferring spec coverage of `vim.fn.input` interaction to whatever sub-issue eventually wants UI integration tests; not in scope here. |
| `vim.trim` | In-process (Neovim Lua stdlib) | Used inside `args` functions. No spec implication. |
| `mini.test` | In-process (test runner) | Existing harness from cycle 01. New cases live under `tests/config/commands_registrar_spec.lua`. |

No new seam introduced. The registrar gains one new spec-row key
(`nargs`), which forwards to an existing field on
`nvim_create_user_command`'s opts.

## Interface design

This sub-issue makes one registrar shape decision. Two alternatives
considered. Alternative C (experience-heavy) is not applicable —
this is mechanism work.

### Alternative A — Add only `nargs` forwarding now

Whitelist `nargs` as a top-level optional spec-row key. The registrar
copies `spec.nargs` into the opts table when present.

```lua
local function register(spec)
  local opts = { desc = spec.desc }
  if spec.nargs ~= nil then opts.nargs = spec.nargs end
  vim.api.nvim_create_user_command(spec.name, function(cmd_opts)
    -- (callback body unchanged from #23)
  end, opts)
end
```

`complete`, `range`, `bang` stay deferred until a command needing
them migrates. Every spec-row key in the registrar has at least one
row exercising it.

### Alternative B — Add the full forward allowlist now

Land all four optional forwards (`nargs`, `complete`, `range`, `bang`)
in one registrar edit. Only `nargs` is exercised by current rows; the
other three are dead-but-supported until later batches.

```lua
local function register(spec)
  local opts = { desc = spec.desc }
  for _, k in ipairs({ "nargs", "complete", "range", "bang" }) do
    if spec[k] ~= nil then opts[k] = spec[k] end
  end
  vim.api.nvim_create_user_command(spec.name, function(cmd_opts)
    -- (callback body unchanged from #23)
  end, opts)
end
```

### Comparison

- **Leverage.** A and B are the same functional capability for
  current rows. B saves one registrar edit later (when `WordCount`
  migrates and needs `range`); A pushes that edit to the sub-issue
  that needs it.
- **Locality.** A keeps the registrar's contract tight: every key
  it accepts is in use today. B widens the contract with three
  unused keys; the registrar spec covers only the exercised one,
  which means three keys exist with no test until later.
- **Testability.** A is testable end-to-end: every spec-row key has
  at least one exercising row in `commands.lua` and at least one
  spec case in `commands_registrar_spec.lua`. B requires that the
  registrar spec covers all four keys via stub specs even without
  consumer rows — otherwise three keys ship untested.
- **Future-proofing.** A produces a registrar that grows one shape
  decision per sub-issue, in lockstep with consumers. B front-loads
  forward decisions before consumers exist; if `complete` or `bang`
  never get exercised by any of the 18 commands, they ship as
  permanent dead surface.

### Chosen: A

Reason for rejecting B: B trades a dead-surface risk for one
deferred registrar edit. The cycle PRD's discipline — and the
parent issue's stated approach ("optional forwards (nargs/complete/
range/bang) added in subsequent sub-issues as commands needing them
migrate") — favors A. `range` lands when `WordCount` migrates;
`complete` and `bang` may never land if no command needs them.

### Spec-row schema after this sub-issue

```lua
register({
  name          = "...",   -- required, forwarded as user-command name
  desc          = "...",   -- required, becomes opts.desc
  module        = "...",   -- required, the leaf to require
  fn            = "...",   -- required, the key on the required module
  args          = function(cmd_opts) return { ... } end,  -- optional; default {}
  on_load_error = "...",   -- optional; defaults to "Failed to load " .. module
  nargs         = "?" | "*" | "+" | <number> | <string>,  -- optional; forwarded to opts.nargs
})
```

Three forwards remain deferred: `complete` (no consumer in cycle 03
scope), `range` (lands with `WordCount`), `bang` (no consumer).

### `args` calling `vim.fn.input` is a usage pattern, not a new shape

`ObsCLIHistoryRead` and `ObsCLIDiffFrom`'s `args` functions both
call `vim.fn.input` when `cmd_opts.args` is empty. The registrar
already supports this — `args` is a Lua function the registrar
invokes; the function may do anything that returns a table-or-nil.
No new spec-row key, no new registrar branch.

This is recorded under "Interface design" so the AAR captures it
explicitly: the `args` function is the chosen vehicle for "prompt
the user when the user-command argument is empty", in preference
to a registrar-level `prompt` key. The latter would be a new shape
decision and is out of scope.

The decision means `args` functions are no longer pure
transformations of `cmd_opts` — they may have side effects (a
modal prompt). This is allowed by the registrar's contract as
written; the contract does not promise purity.

### Entry points, inputs, outputs, invariants, error modes

- **Entry point unchanged:** `commands.register(spec)`.
- **New input field:** `spec.nargs` — optional; when present,
  forwarded verbatim to `nvim_create_user_command`'s opts.
- **Outputs unchanged.** No return value.
- **Invariant carry-forward from #23:** the registrar calls
  `nvim_create_user_command` exactly once per `register` call. The
  callback never throws under any of the four return-shape branches.
- **New invariant:** when `spec.nargs` is `nil`, the recorded
  `opts.nargs` is `nil` (no key written). When `spec.nargs` is set,
  the recorded `opts.nargs` equals `spec.nargs`.
- **Error modes unchanged.** Load failure, leaf failure, leaf
  success with message, leaf success silent — same four branches
  as #23.

## Acceptance criteria

- [ ] Each of the five commands — `ObsCLIHistoryRead`,
      `ObsCLIDiffFrom`, `ObsCLIOutline`, `ObsCLIBacklinks`,
      `ObsCLIBookmarkAdd` — is registered through
      `commands.register` with the spec-row shape including
      `nargs`, `module = "utils.obsidian_cli"`, `fn`, and an
      `args` function reproducing the inline block's pre-migration
      argument logic.
- [ ] Each migrated row preserves its `desc` string and `nargs`
      value verbatim from the pre-migration inline block.
      Verified by diffing pre-sub-issue `commands.lua` against the
      new `commands.lua` for those five descriptions and `nargs`
      values.
- [ ] `lua/config/commands_registrar.lua` forwards `spec.nargs` to
      `nvim_create_user_command`'s `opts` table when set, and
      writes no `opts.nargs` key when `spec.nargs` is `nil`. No
      other forward keys (`complete`, `range`, `bang`) are added.
- [ ] After migration, `lua/config/commands.lua` contains zero
      direct calls to `vim.api.nvim_create_user_command` for any
      of the five migrated commands. Verified by
      `grep -n 'nvim_create_user_command(\"\(ObsCLIHistoryRead\|ObsCLIDiffFrom\|ObsCLIOutline\|ObsCLIBacklinks\|ObsCLIBookmarkAdd\)\"' lua/config/commands.lua`
      returning zero matches.
- [ ] After migration, `lua/config/commands.lua` contains zero
      occurrences of the inline `pcall(require, "utils.obsidian_cli")`
      → call → `vim.notify` block for any of the five migrated
      commands. (Two such blocks remain — `ObsCLISearchContext` and
      `ObsCLIWordCount` — and migrate in later sub-issues.)
- [ ] The 6 commands not migrated in this sub-issue —
      `SolarizedToggle`, `SolarizedDark`, `SolarizedLight`,
      `ObsCLISearchContext`, `WordCount`, `ObsCLIWordCount` — are
      byte-for-byte unchanged from pre-sub-issue state. Verified
      by `git diff` on `commands.lua` showing edits only inside
      the five migrated blocks (plus possible whitespace/section-
      comment adjustments adjacent to them).
- [ ] No edits to `lua/utils/obsidian_cli/` (any file). The leaf
      module's public surface is consumed unchanged.
- [ ] `tests/config/commands_registrar_spec.lua` gains at least
      one new case asserting that a spec with `nargs = "?"`
      produces a recorded `opts.nargs == "?"`, and at least one
      assertion (in a new or existing case) that a spec without
      `nargs` produces a recorded `opts.nargs == nil`.
- [ ] All seven inherited cases in
      `tests/config/commands_registrar_spec.lua` from #23 still
      pass unchanged. The new cases do not delete or weaken any
      existing assertion.
- [ ] `./tests/run` exits 0 on the whole suite — including all
      cycle 01 specs, cycle 02 specs, the registrar spec from #23,
      and the new `nargs` forwarding cases.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent —
      the suite passes with `obsidian` and `codesign` absent from
      `$PATH`).
- [ ] Live smoke check — recorded in the AAR, not a committed
      spec — invokes each of the five migrated commands inside
      Neovim and confirms observable behavior matches
      pre-migration: `ObsCLIHistoryRead` and `ObsCLIDiffFrom` with
      no argument prompt via `vim.fn.input` and pass the result to
      the leaf; `ObsCLIHistoryRead` and `ObsCLIDiffFrom` with an
      argument skip the prompt; `ObsCLIOutline` with no argument
      defaults to `"tree"`; `ObsCLIBacklinks` with no argument
      passes `nil` to the leaf; `ObsCLIBookmarkAdd` with no
      argument passes `nil` title; with an argument passes the
      trimmed string.
- [ ] `wc -l lua/config/commands.lua` is strictly less than the
      pre-sub-issue line count (299). The <120-line target for
      parent #22 closure is not reached by this sub-issue alone.
- [ ] No reaching into local functions or monkey-patching internals
      in the new spec cases. The new cases use the same
      `pre_case`/`post_case` API swaps from #23. Carry-forward
      acceptance criterion from cycles 01 and 02.
- [ ] AAR records: the registrar diff (the `nargs` forwarding
      addition), the line-count delta on `commands.lua`, the
      live-smoke-check result for each of the five commands, and
      any flags surfaced for subsequent migration sub-issues
      (especially: whether `args`-calling-`vim.fn.input` produced
      any unexpected behavior the spec did not catch).

## Proposed tests

Two new cases land in `tests/config/commands_registrar_spec.lua`.
The seven cases from #23 stay unchanged.

| Title | What it verifies |
| --- | --- |
| `register: forwards spec.nargs to opts.nargs` | A spec row with `nargs = "?"` produces a recorded `nvim_create_user_command` call whose `opts.nargs` equals `"?"`. Same row's `opts.desc` still equals the spec's `desc` (regression guard against the new field clobbering existing forwarding). |
| `register: omits opts.nargs when spec.nargs is nil` | A spec row without `nargs` produces a recorded `opts.nargs == nil` (or absent key). The pre-existing seven cases all use this shape and stay green; this case asserts the new forwarding code path is correctly conditional. |

The first case is the Stage-2 First Contact for `nargs` forwarding.
The second locks the conditional behavior so that future forwards
(`complete`, `range`, `bang`) added by later sub-issues do not
silently widen `opts` for spec rows that omit them.

A deliberate-failure verification runs once during implementation:
mutate the registrar's `nargs` forwarding to write
`opts.nargs = spec.nargs or "?"` (forcing a default). Confirm the
"omits opts.nargs when spec.nargs is nil" case goes red. Revert.
Recorded in the AAR.

The `args`-calling-`vim.fn.input` behavior on `ObsCLIHistoryRead` and
`ObsCLIDiffFrom` is *not* covered by a new spec — the registrar has
no opinion on `args` internals, and stubbing `vim.fn.input` to assert
the prompt would be testing the migrated row's `args` function, not
the registrar's contract. The live smoke check is the verification
for that pattern.

## Affected artifacts

- Edited: `lua/config/commands.lua` — the five command blocks for
  `ObsCLIHistoryRead`, `ObsCLIDiffFrom`, `ObsCLIOutline`,
  `ObsCLIBacklinks`, `ObsCLIBookmarkAdd` are replaced by
  `commands.register({ ... })` spec rows in place. Each migrated
  row carries `nargs`, `args`, `desc`, `module`, `fn`.
- Edited: `lua/config/commands_registrar.lua` — adds conditional
  `opts.nargs = spec.nargs` forwarding inside the existing
  `register` function. No other behavior changes.
- Edited: `tests/config/commands_registrar_spec.lua` — adds at
  least two new cases (per "Proposed tests" above). No existing
  case is altered.
- Unchanged: `lua/utils/obsidian_cli/` (any file).
- Unchanged: `lua/colors/solarized.lua`.
- Unchanged: `lua/utils/wordcount.lua`.
- Unchanged: `tests/init.lua`, `tests/run`, all other specs.
- New: this sub-issue's `aar.md` on close.

## Dependencies

- **#23 closure** — `commands.register` exists at
  `lua/config/commands_registrar.lua` with the spec-row schema
  (`name`, `desc`, `module`, `fn`, optional `args`,
  `on_load_error`). This sub-issue extends that schema with one
  optional key. Already closed.
- **#24 closure** — established the per-row migration pattern
  (Alternative A, six explicit `register({...})` calls; spec-row
  ordering preserved alongside section comments). This sub-issue
  inherits the pattern unchanged. Already closed.
- **Cycle 02 closure (parent #13)** —
  `lua/utils/obsidian_cli/init.lua` exposes
  `history_read_current(v)`, `diff_current_from(v)`,
  `outline_current(opts_table)`,
  `backlinks_counts_to_quickfix(path_or_nil)`,
  `bookmark_add_current({ title = ... })` with the
  `(success, msg)` envelope. Verified by inspection at the
  migration call sites.
- **Cycle 01 closure** — `mini.test` harness at `./tests/run`.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `25-nargs-obscli-rows` tracks GitHub
  issue #25.
- No dependency on any other cycle 03 sub-issue beyond #23 and #24.

## Out of scope (deferred to subsequent sub-issues of parent #22)

- Migration of `ObsCLISearchContext`. It surfaces a WARN-level
  early return on empty `vim.fn.input` — a new spec-row shape
  decision (early-return-with-warn signalling, or some equivalent
  contract for "abort, don't call the leaf"). That decision lands
  with whatever sub-issue takes the early-return shape on first.
- Migration of the three `Solarized*` commands. Their leaves
  (`set_theme`, `toggle`) do not return `(success, msg)`. The void-
  return shape decision — variant spec, separate `register_void`,
  or thin `(true, "")` adapter — is a parent #22 deferred decision.
- Migration of `WordCount` and `ObsCLIWordCount`. Both involve
  shape decisions outside this batch: `WordCount` carries
  `range = true` (new forward) plus a custom synthesized notify
  message that does not flow from the leaf's return; `ObsCLIWordCount`
  carries `nargs = "*"` (covered by this sub-issue's forward) but
  the parent issue groups them as one batch — they migrate together
  to keep the WordCount-shape decisions in one place.
- Adding `complete`, `range`, or `bang` forwarding to the registrar.
  `range` lands with `WordCount`. `complete` and `bang` land if and
  when a consumer needs them; otherwise they never land.
- Hardening the registrar against missing-`fn` calls (the
  deliberate-failure verification flag-check from #24's AAR). If
  the verification surfaces an ugly Lua error rather than a
  graceful ERROR notify, that becomes a parent #22 flag, not
  scope here.
- Spec coverage of the `args`-calling-`vim.fn.input` pattern. The
  live smoke check is the chosen verification for that path. UI-
  integration spec coverage of any modal prompt is out of scope
  per cycle PRD non-goal #6.
- Candidate F (domain split of `commands.lua`) decision. Closing
  sub-issue of parent #22.
- ADR-0004 candidacy for the registrar pattern. Per cycle PRD open
  question 4, deferred until at least one more seam (Candidate B
  or D) is in place.
