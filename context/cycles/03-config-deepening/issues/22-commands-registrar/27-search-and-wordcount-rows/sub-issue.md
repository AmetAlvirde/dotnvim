# Sub-issue — Search and WordCount commands migration

GitHub issue: #27. Fifth sub-issue of parent #22, after #23's tracer,
#24's no-arg ObsCLI batch, #25's `nargs`-bearing ObsCLI batch, and
#26's Solarized void-return batch. Migrates the three remaining
inline `vim.api.nvim_create_user_command` blocks in
`lua/config/commands.lua` — `ObsCLISearchContext`, `WordCount`, and
`ObsCLIWordCount` — onto `commands.register`. Introduces three new
spec-row shape decisions (one per command), each carried in parent
#22's "Implementation approach" as deferred or out-of-scope-for-the-
prior-sub-issue:

1. **Abort-from-`args` shape** (for `ObsCLISearchContext`'s
   WARN-level early return on empty prompt input). Resolved as
   Alternative A — `args` may return `(nil, msg, level)` to abort
   the dispatch with one notify; no new spec key, no new `kind`
   value.
2. **`range` forwarding** (for `WordCount`'s `range = true`).
   Resolved as Alternative A — one conditional line in the
   registrar, mirroring `nargs` from #25.
3. **`kind = "synthesized_notify"` shape** (for `WordCount`'s
   custom INFO message synthesized from the leaf's return plus
   `cmd_opts`). Resolved as Alternative A — new `kind` value plus
   an optional `notify = function(returns, cmd_opts)` callback,
   directly extending the `kind` enum #26 introduced.

After this sub-issue lands, every user command in `commands.lua` is
registered through `commands.register`, and the file contains zero
direct calls to `vim.api.nvim_create_user_command`. Parent #22's
closing sub-issue (Candidate F decision — domain split or skip)
becomes the only remaining work.

## Description

Migrate three user commands in `lua/config/commands.lua` from inline
`vim.api.nvim_create_user_command(..., function() ... end, { ... })`
shape onto `commands.register({ ... })` spec rows.

| Command | Leaf | New shape decision exercised |
| --- | --- | --- |
| `ObsCLISearchContext` | `utils.obsidian_cli.search_context_to_quickfix(query)` | abort-from-`args` (WARN on empty prompt) |
| `WordCount` | `utils.wordcount.buf_line_range_wordcount(0, line1, line2)` | `range` forwarding + `kind = "synthesized_notify"` |
| `ObsCLIWordCount` | `utils.obsidian_cli.wordcount_current({ path_rel, mode })` | none new — uses `args` parsing already supported, `nargs = "*"` from #25 |

`ObsCLIWordCount` carries no new shape decision. It exercises the
existing surface (`nargs = "*"`, `args` function with non-trivial
parsing, standard `(success, msg)` envelope) and lands in this
sub-issue alongside `WordCount` because parent #22 grouped them in
its sequencing plan.

Three edits to `lua/config/commands_registrar.lua`:

1. **Abort branch.** After evaluating `spec.args(cmd_opts)`, inspect
   the multi-value return. If the first value is `nil` and a second
   value is present, treat it as `(nil, msg, level)`: emit
   `vim.notify(msg, level or vim.log.levels.WARN)` and return.
   Otherwise treat the first value as the args table and proceed.
2. **`range` forwarding.** Add
   `if spec.range ~= nil then opts.range = spec.range end` next to
   the existing `nargs` line.
3. **`kind = "synthesized_notify"` branch.** After `pcall(require)`
   and `args` evaluation, before the existing `(success, msg)`
   envelope unpacking, branch on `spec.kind == "synthesized_notify"`:
   call the leaf with unpacked args, capture all returns into a
   table, call `spec.notify(returns, cmd_opts)` to obtain
   `(msg, level)` (or nil). If `(msg, level)` is non-nil, emit one
   `vim.notify(msg, level)`. Return.

Five new cases added to `tests/config/commands_registrar_spec.lua`,
covering: the abort branch fires WARN and skips the leaf; the abort
branch passes through normal args when `args` returns a single table;
`range` forwarding mirrors `nargs`; `kind = "synthesized_notify"`
invokes the `notify` callback with the leaf's returns and emits one
notify; `kind = "synthesized_notify"` still surfaces load failure as
ERROR. Twelve inherited cases (seven from #23, two from #25, three
from #26) stay unchanged.

`commands.lua` retains its current section-comment structure and
ordering. Only the three migrated blocks change shape; no other
spec row is edited.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `commands.register` | In-process (owned, this cycle) | Edited in this sub-issue. Three new branches (abort, `range`, `synthesized_notify`) covered by five new cases. Twelve inherited cases stay unchanged. |
| `utils.obsidian_cli` (`search_context_to_quickfix`, `wordcount_current`) | In-process (consumer-side, owned, frozen by parent #22 constraint #2) | Public surface unchanged. Migration is pass-through. |
| `utils.wordcount` (`buf_line_range_wordcount`) | In-process (consumer-side, owned, frozen by parent #22 constraint #2) | Public surface unchanged. Migration is pass-through. |
| `vim.api.nvim_create_user_command` | In-process (Neovim API) | Reached via `commands.register` only. New `range = true` row produces a recorded `opts.range = true`. |
| `vim.notify` | In-process (Neovim API) | Reached via `commands.register` only. The abort branch emits one WARN; the `synthesized_notify` branch emits one INFO (or whatever the `notify` callback returns). |
| `vim.fn.input` | In-process (Neovim API) | Called only inside `args` for `ObsCLISearchContext`. Stubbable per-test by setting `vim.fn.input` similar to the existing `vim.notify` swap. New abort-branch cases use a stub `args` function directly to avoid coupling registrar specs to `vim.fn.input` shape. |
| `mini.test` | In-process (test runner) | Existing harness from cycle 01. New cases live under `tests/config/commands_registrar_spec.lua`. |

No new seam introduced. The registrar gains:

- One new interpretation of `args`'s multi-value return (abort tuple).
- One new spec-row key (`range`), forwarded to user-command opts.
- One new `kind` value (`"synthesized_notify"`) plus one new optional
  spec-row callback (`notify`).

## Interface design

This sub-issue makes three registrar shape decisions. Each is
independently designed below with at least two alternatives and a
chosen-with-reason.

---

### Decision 1 — Abort-from-`args` shape

`ObsCLISearchContext` has a WARN-level early return on empty
`vim.fn.input`. The leaf must not be called when the prompt yields
an empty query; instead, `vim.notify("Search query required.",
vim.log.levels.WARN)` fires and the dispatch ends.

#### Alternative 1A — Multi-value return from `args`

`args` may return either:

- a single table → normal flow; registrar calls leaf with
  `unpack(args_table)`.
- `(nil, msg, level)` → abort; registrar emits
  `vim.notify(msg, level or vim.log.levels.WARN)` and returns.

```lua
register({
  name = "ObsCLISearchContext",
  desc = "Search Obsidian vault with context (quickfix)",
  module = "utils.obsidian_cli",
  fn = "search_context_to_quickfix",
  args = function(_)
    local q = vim.fn.input("Obsidian search query: ")
    if not q or vim.trim(q) == "" then
      return nil, "Search query required.", vim.log.levels.WARN
    end
    return { vim.trim(q) }
  end,
})
```

Registrar diff (sketch):

```lua
local args_table, abort_msg, abort_level = spec.args and spec.args(cmd_opts) or {}
if args_table == nil and abort_msg ~= nil then
  vim.notify(abort_msg, abort_level or vim.log.levels.WARN)
  return
end
-- proceed with args_table
```

No new spec-row key. The decision "should the leaf run?" lives
entirely in `args` — the same place that already prepares the
inputs.

#### Alternative 1B — Separate `validate` callback

Two callbacks. `args` produces; `validate` checks and aborts.

```lua
register({
  name = "ObsCLISearchContext",
  ...
  args = function(_)
    return { vim.fn.input("Obsidian search query: ") }
  end,
  validate = function(args, cmd_opts)
    if not args[1] or vim.trim(args[1]) == "" then
      return false, "Search query required.", vim.log.levels.WARN
    end
    return true
  end,
})
```

#### Alternative 1C — Specialised `prompt` field

Add a `prompt` spec-row key carrying the prompt message and the
required-error message.

```lua
register({
  name = "ObsCLISearchContext",
  ...
  prompt = {
    message = "Obsidian search query: ",
    required_msg = "Search query required.",
  },
  args = function(prompt_value, _) return { vim.trim(prompt_value) } end,
})
```

#### Comparison

- **Leverage.** 1A handles "produce-or-abort" generically; any
  future abort case (e.g., "abort if `cmd_opts.range == 0`") uses
  the same multi-value return. 1B introduces a second callback for
  what is one decision — does the leaf run? 1C only handles the
  prompt-then-validate case; future non-prompt aborts wouldn't fit.
- **Locality.** 1A keeps the abort logic next to the prompt that
  produced the value being checked — same function. 1B splits the
  prompt and the validation across two callbacks; the maintainer
  has to mentally compose them. 1C splits across `prompt` (the
  data) and `args` (the consumption).
- **Testability.** 1A: one new branch in registrar, exercised by
  stub `args` returning the abort tuple. 1B: two callbacks to mock
  per spec, plus a registrar branch combining them. 1C: a third
  registrar branch for prompt handling.
- **Consistency with #25.** #25 established that `args` is the
  single point of truth for "what arguments does the leaf get?".
  1A extends that — `args` also answers "should the leaf get
  called?" — without adding a sibling callback. 1B and 1C bifurcate
  the answer.

#### Chosen — 1A

Reason for rejecting 1B: 1B introduces a parallel callback for
what is one decision. The cycle's discipline is one row per
command, one entry point for "what to do per invocation". `args`
is already that entry point; teaching it to return an abort tuple
is the smallest extension.

Reason for rejecting 1C: 1C only fits the prompt-then-validate
case. The registrar shouldn't grow a special field per validation
shape — a generic mechanism (`args` may abort) covers prompt,
range-required, mode-incompatible, and any future case with one
branch.

---

### Decision 2 — `range` forwarding

`WordCount` declares `range = true` so Neovim accepts `:WordCount`,
`:'<,'>WordCount`, `:%WordCount`, and exposes `cmd_opts.line1` /
`cmd_opts.line2` to the callback. The current registrar forwards
`nargs` only (added in #25); `range` does not flow through.

#### Alternative 2A — One conditional, mirroring `nargs`

```lua
if spec.range ~= nil then opts.range = spec.range end
```

Sits next to the existing `nargs` line. One spec-row key, one new
line in the registrar.

#### Alternative 2B — Bundle `complete`, `range`, `bang` together

Forward all three deferred forwards in one go.

```lua
if spec.complete ~= nil then opts.complete = spec.complete end
if spec.range ~= nil then opts.range = spec.range end
if spec.bang ~= nil then opts.bang = spec.bang end
```

#### Comparison

- **Leverage.** 2A adds what's needed for the one consumer
  (`WordCount`); future forwards land when their consumer surfaces.
  2B forwards three keys with one consumer — `complete` and `bang`
  go untested in production until something uses them, and the
  test suite carries assertions for branches no real row exercises.
- **YAGNI / parent #22.** Parent issue.md's "Implementation
  approach > Spec-row schema after this sub-issue" notes (in #26):
  "`complete`, `range`, `bang` forwards remain deferred. `range`
  lands when `WordCount` migrates." 2A obeys that contract.

#### Chosen — 2A

Reason for rejecting 2B: parent #22 explicitly defers `complete`
and `bang` until a consumer needs them. None exists in cycle 03.
Adding their forwards now means three new test cases (one omits
each, one forwards each) for branches no production row exercises
— surface area without payoff.

---

### Decision 3 — `kind = "synthesized_notify"` shape

`WordCount`'s leaf returns `n` (an integer word count). The
callback synthesizes a string from `n` and `cmd_opts.line1` /
`cmd_opts.line2`:

```lua
string.format("%d word%s (lines %d–%d)", n, n == 1 and "" or "s", opts.line1, opts.line2)
```

and emits it as INFO. The leaf does not return the `(success, msg)`
envelope, and the message is not derivable from `n` alone — it
needs `cmd_opts`.

#### Alternative 3A — `kind = "synthesized_notify"` + `notify` callback

New `kind` value. New optional `notify` spec-row key: a function
taking `(returns, cmd_opts)` and producing `(msg, level)` — or nil
to skip the notify.

```lua
register({
  name = "WordCount",
  desc = "Count whitespace-separated words in range (default: current line; use % or '<,'>)",
  module = "utils.wordcount",
  fn = "buf_line_range_wordcount",
  range = true,
  kind = "synthesized_notify",
  args = function(opts) return { 0, opts.line1, opts.line2 } end,
  notify = function(returns, cmd_opts)
    local n = returns[1]
    return string.format(
      "%d word%s (lines %d–%d)",
      n, n == 1 and "" or "s", cmd_opts.line1, cmd_opts.line2
    ), vim.log.levels.INFO
  end,
})
```

Registrar diff (sketch):

```lua
if spec.kind == "synthesized_notify" then
  local returns = { mod[spec.fn](unpack(args_table)) }
  local msg, level = spec.notify(returns, cmd_opts)
  if msg then
    vim.notify(msg, level or vim.log.levels.INFO)
  end
  return
end
```

Branch sits between the `kind == "void"` branch and the
`(success, msg)` envelope, matching #26's ordering:
`pcall(require)` → `args` (with abort) → `void` branch →
`synthesized_notify` branch → envelope.

#### Alternative 3B — Inline adapter in `commands.lua`

Wrap the leaf in a local function that returns `(true, synthesized_msg)`:

```lua
-- in commands.lua
local function _wordcount_with_msg(line1, line2)
  local wc = require("utils.wordcount")
  local n = wc.buf_line_range_wordcount(0, line1, line2)
  return true, string.format("%d word%s (lines %d–%d)", n, n == 1 and "" or "s", line1, line2)
end
```

Then either:

- edit `utils.wordcount` to add `buf_line_range_wordcount_with_msg`
  (forbidden by parent #22 constraint #2), or
- place the adapter in a new module under `lua/config/` or
  `lua/utils/` (adapter-home machinery), or
- pass the adapter via `package.loaded` injection in `commands.lua`
  (a hack, addressable through `module = "..."` / `fn = "..."`
  strings).

#### Alternative 3C — Presence-of-`notify` as the discriminator

Don't add a `kind` value. Instead, if `notify` is set on a spec,
the registrar bypasses the `(success, msg)` envelope and routes the
leaf's returns through `notify` directly.

```lua
register({
  name = "WordCount",
  ...
  notify = function(returns, cmd_opts) return msg, level end,
  -- no kind
})
```

Registrar uses `if spec.notify then ... end` instead of
`if spec.kind == "synthesized_notify" then ... end`.

#### Comparison

- **Leverage.** 3A and 3C are the same functional capability. 3B is
  the same too, but with adapter-home overhead. 3A and 3C let the
  caller customise the message in one place; 3B requires inventing
  an adapter home.
- **Locality / consistency with #26.** 3A extends `kind`'s enum
  (already `"void"` from #26) by one value. The registrar's
  callback reads as a chain of `kind`-discriminated branches plus a
  default envelope tail. 3C introduces a parallel discriminator —
  some shapes are picked by `kind`, others by presence of `notify`
  — bifurcating the maintainer's mental model. Parent #22 already
  named `kind` as the shape discriminator.
- **Testability.** 3A: one new `kind` branch. Tests assert the
  branch fires when `kind == "synthesized_notify"` and skips
  otherwise. 3C: presence-of-`notify` test plus interaction with
  `kind` (e.g., does `kind = "void"` + `notify = fn` make sense?
  No — undefined). 3A keeps `kind` mutually exclusive across
  branches; 3C invites the cross-product question.
- **Constraint compliance.** 3A and 3C both comply with parent
  #22's no-edit constraint on `lua/utils/wordcount.lua`. 3B in its
  cleanest form (edit wordcount.lua) violates it; in its
  workaround forms (adapter module, `package.loaded` injection) it
  adds machinery for no payoff over 3A.

#### Chosen — 3A

Reason for rejecting 3B: same as #26's rejection of option C. The
clean form is forbidden by the no-edit constraint; the workarounds
add adapter-module machinery for no payoff over treating the
synthesis as a registrar-level concern.

Reason for rejecting 3C: parent #22's "Implementation approach"
treats `kind` as the single shape discriminator. 3C makes `kind`
and `notify`-presence two parallel discriminators, raising
cross-product questions (e.g., what does `kind = "void"` plus
`notify = fn` mean?). 3A keeps `kind` mutually exclusive across
branches and matches the precedent #26 set.

---

### Spec-row schema after this sub-issue

```lua
register({
  name          = "...",   -- required, forwarded as user-command name
  desc          = "...",   -- required, becomes opts.desc
  module        = "...",   -- required, the leaf to require
  fn            = "...",   -- required, the key on the required module
  args          = function(cmd_opts)
                    -- single-table return → normal flow
                    -- (nil, msg, level) → abort with notify
                  end,                                            -- optional; default {}
  on_load_error = "...",                                          -- optional; defaults to "Failed to load " .. module
  nargs         = "?" | "*" | "+" | <number> | <string>,          -- optional; forwarded to opts.nargs
  range         = true | <integer> | <string>,                    -- optional; forwarded to opts.range  (NEW)
  kind          = "void" | "synthesized_notify",                  -- optional; switches callback shape  (EXTENDED)
  notify        = function(returns, cmd_opts) return msg, level end,
                                                                  -- optional; required when kind == "synthesized_notify"  (NEW)
})
```

`complete` and `bang` forwards remain deferred. `kind`'s value
space is now `"void"` and `"synthesized_notify"`. Future shapes
introduce additional values, each in its own sub-issue with its
own branch.

### Behavior change recorded under interface design

Pre-migration, `:WordCount` invoked with `utils.wordcount` failing
to load surfaced an uncaught Lua error. Post-migration, it
surfaces an ERROR-level `vim.notify("Failed to load
utils.wordcount")`. Same shape of behavior improvement #26
recorded for the Solarized commands. There is no realistic
load-failure scenario in normal use; the regression check is the
live smoke check, not a spec.

`:ObsCLISearchContext` and `:ObsCLIWordCount` already had
`pcall(require)` and ERROR-notify load-failure handling in their
inline blocks; no behavior change for those two commands.

### Entry points, inputs, outputs, invariants, error modes

- **Entry point unchanged:** `commands.register(spec)`.
- **New input shape on `args`:** `args` may return a tuple
  `(nil, msg, level)` to abort. Existing single-table return
  behavior is preserved.
- **New input field:** `spec.range` — optional; forwarded to
  `opts.range`. Mirrors `spec.nargs`.
- **New `kind` value:** `"synthesized_notify"`. Requires
  `spec.notify = function(returns, cmd_opts) return msg, level end`.
- **Outputs unchanged.** No return value.
- **Invariant carry-forward:** `nvim_create_user_command` is
  called exactly once per `register` call. The callback never
  throws under any branch. Load-failure handling is identical
  across all branches (default envelope, `void`,
  `synthesized_notify`, abort).
- **New invariant — abort branch:** when `args` returns
  `(nil, msg, level)`, the leaf is not called and exactly one
  `vim.notify(msg, level or vim.log.levels.WARN)` fires.
- **New invariant — `synthesized_notify`:** when `kind ==
  "synthesized_notify"` and `notify` returns `(msg, level)`,
  exactly one `vim.notify(msg, level or vim.log.levels.INFO)`
  fires. When `notify` returns nil, no notify fires.
- **Error modes:** load failure unchanged. Leaf-failure /
  leaf-success-with-message branches fire only for default-envelope
  rows (no `kind`).

## Acceptance criteria

- [ ] Each of the three commands — `ObsCLISearchContext`,
      `WordCount`, `ObsCLIWordCount` — is registered through
      `commands.register` with the correct `module`, `fn`, `desc`,
      and (where applicable) `nargs` / `range` / `kind` / `args` /
      `notify` keys. `desc` strings are preserved verbatim from
      the pre-migration inline blocks.
- [ ] `lua/config/commands_registrar.lua` honors:
      1. an abort tuple `(nil, msg, level)` returned from `spec.args`
         by emitting `vim.notify(msg, level or vim.log.levels.WARN)`
         and returning without calling the leaf;
      2. `spec.range` by forwarding it to `opts.range` when non-nil
         and omitting it when nil (mirroring the existing `nargs`
         line);
      3. `spec.kind == "synthesized_notify"` by calling the leaf
         with unpacked args, capturing all returns into a table,
         calling `spec.notify(returns, cmd_opts)`, and emitting one
         `vim.notify(msg, level or vim.log.levels.INFO)` if `(msg,
         level)` is returned (no notify if `notify` returns nil).
- [ ] After migration, `lua/config/commands.lua` contains zero
      direct calls to `vim.api.nvim_create_user_command`. Verified
      by `grep -n 'nvim_create_user_command' lua/config/commands.lua`
      returning zero matches.
- [ ] After migration, `lua/config/commands.lua` contains zero
      direct `pcall(require, "utils.obsidian_cli")` and zero direct
      `pcall(require, "utils.wordcount")` calls. The `module`
      strings in spec rows do not count.
- [ ] No edits to `lua/utils/obsidian_cli/` (any file). Public
      surface (`search_context_to_quickfix`, `wordcount_current`)
      consumed unchanged. Verified by `git diff` showing no
      changes to those files.
- [ ] No edits to `lua/utils/wordcount.lua`. Public surface
      (`buf_line_range_wordcount`) consumed unchanged. Verified by
      `git diff` showing no changes.
- [ ] No edits to `lua/colors/solarized.lua` or other previously
      migrated rows. The 15 already-migrated `register({ ... })`
      blocks (3 Solarized + 12 ObsCLI) remain byte-for-byte
      unchanged except for ordering / section-comment adjacency
      surrounding the three newly migrated blocks.
- [ ] `tests/config/commands_registrar_spec.lua` gains five new
      cases:
      1. `args` returning `(nil, "msg", level)` triggers exactly
         one `vim.notify("msg", level)` and the leaf is not called;
      2. `args` returning `(nil, "msg")` (omitting `level`) defaults
         to `vim.log.levels.WARN`;
      3. `register` forwards `spec.range` to `opts.range` when set
         and omits `opts.range` when nil (mirrors the `nargs`
         pair);
      4. `kind = "synthesized_notify"` calls the leaf with unpacked
         args, captures returns, calls `spec.notify(returns,
         cmd_opts)`, and emits exactly one notify with the returned
         `(msg, level)`;
      5. `kind = "synthesized_notify"` whose `module` fails to load
         emits exactly one ERROR notify with the load-failure
         message and does not call `notify`.
- [ ] All twelve inherited cases (seven from #23, two from #25,
      three from #26) in `tests/config/commands_registrar_spec.lua`
      still pass unchanged. The new cases do not delete or weaken
      any existing assertion.
- [ ] `./tests/run` exits 0 on the whole suite — including all
      cycle 01 specs, cycle 02 specs, and the registrar spec with
      its new cases.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent —
      the suite passes with `obsidian` and `codesign` absent from
      `$PATH`).
- [ ] Live smoke check — recorded in the AAR, not a committed
      spec — invokes each of the three migrated commands inside
      Neovim and confirms observable behavior matches
      pre-migration:
      - `:ObsCLISearchContext` with empty input → WARN notify
        "Search query required.", no quickfix population.
      - `:ObsCLISearchContext` with non-empty input → quickfix
        populated (or ERROR notify if leaf fails).
      - `:WordCount` (no range) → INFO notify with current-line
        word count and `(lines N–N)` suffix.
      - `:'<,'>WordCount` (visual range) → INFO notify with the
        selected range's word count.
      - `:%WordCount` → INFO notify with the whole buffer's word
        count.
      - `:ObsCLIWordCount` (no args) → leaf called with
        `{ path_rel = nil, mode = "full" }`.
      - `:ObsCLIWordCount words` → leaf called with `{ path_rel =
        nil, mode = "words" }`.
      - `:ObsCLIWordCount path/to/note.md` → leaf called with
        `{ path_rel = "path/to/note.md", mode = "full" }`.
      - `:ObsCLIWordCount path/to/note.md chars` → leaf called
        with `{ path_rel = "path/to/note.md", mode = "characters" }`.
- [ ] Parent `issue.md` records the resolution of all three shape
      decisions in its "Implementation approach" section:
      Decision 1 chose Alternative A (multi-value return from
      `args` for abort); Decision 2 chose Alternative A (one
      conditional `range` line, mirroring `nargs`); Decision 3
      chose Alternative A (`kind = "synthesized_notify"` plus
      `notify` callback). Each with a one-sentence rejection
      reason for the rejected alternatives.
- [ ] No reaching into local functions or monkey-patching internals
      in the new spec cases. The new cases use the same
      `pre_case` / `post_case` API swaps from #23.
- [ ] AAR records: the three registrar diffs, the line-count delta
      on `commands.lua`, the live-smoke-check result for each of
      the eight observable scenarios above, the deliberate-failure
      verification result (see "Proposed tests"), and any flags
      surfaced for the closing sub-issue (Candidate F decision).

## Proposed tests

Five new cases land in `tests/config/commands_registrar_spec.lua`.
The twelve inherited cases stay unchanged.

| Title | What it verifies |
| --- | --- |
| `register: args returning (nil, msg, level) emits one notify and skips leaf` | Stub leaf would record any call. Spec row has `args = function(_) return nil, "abort msg", vim.log.levels.WARN end`. Invoking the recorded callback emits exactly one notify with `(msg = "abort msg", level = WARN)`; the stub leaf is never called. |
| `register: args returning (nil, msg) defaults level to WARN` | Same shape as above, but `args` returns only `(nil, "abort msg")`. Recorded notify has `level = vim.log.levels.WARN`. |
| `register: forwards spec.range to opts.range` (and the paired omits-when-nil case) | Mirrors the existing `nargs` pair. One case sets `range = true` and asserts `recorded_commands[1].opts.range == true`; the paired case omits `range` and asserts `recorded_commands[1].opts.range == nil`. |
| `register: kind = "synthesized_notify" calls notify with leaf returns and emits one notify` | Stub leaf returns `7` (a single value). Spec has `kind = "synthesized_notify"` and `notify = function(returns, cmd_opts) return "got " .. returns[1] .. " at line " .. cmd_opts.line1, vim.log.levels.INFO end`. Invoking the recorded callback with `cmd_opts = { line1 = 3 }` emits one notify with `msg = "got 7 at line 3"`, `level = INFO`. |
| `register: kind = "synthesized_notify" still surfaces load failure as ERROR notify` | Spec has `kind = "synthesized_notify"`, `module = "utils.does_not_exist"`, `notify = function() error("must not be called") end`. Invoking the callback emits exactly one ERROR notify with the load-failure message; `notify` is not called. |

The first case is the Stage-2 First Contact for the abort branch.
The second locks the level-default contract. The third mirrors
the `nargs` pattern from #25 for `range`. The fourth is the
Stage-2 First Contact for `synthesized_notify`. The fifth is the
sanity guard that `synthesized_notify` composes with load-failure
unchanged.

A `notify`-returns-nil case (skip-the-notify) is *not* added in
this sub-issue. No production row uses that path; adding the case
adds untested-in-production assertion surface. If a future row
needs it, it lands with that row.

A deliberate-failure verification runs once during implementation:

1. Move the abort-branch check above `pcall(require)`. Confirm the
   abort tests stay green (they don't depend on load-failure
   ordering) but the existing load-failure cases still go red
   appropriately if the stub leaf changes — manual judgement call.
   Revert.
2. Move the `kind = "synthesized_notify"` branch above
   `pcall(require)`. Confirm the "synthesized_notify still
   surfaces load failure" case goes red. Revert.

Both verifications recorded in the AAR.

## Affected artifacts

- Edited: `lua/config/commands.lua` — three inline blocks
  (`ObsCLISearchContext`, `WordCount`, `ObsCLIWordCount`) replaced
  by `commands.register({ ... })` spec rows in place. Section
  comments preserved.
- Edited: `lua/config/commands_registrar.lua` — three additions:
  abort-tuple inspection on `spec.args`'s multi-value return;
  conditional `opts.range` forwarding; new `kind ==
  "synthesized_notify"` branch with `spec.notify` callback. Each
  addition is a small, local edit; the existing default-envelope
  branch is unchanged.
- Edited: `tests/config/commands_registrar_spec.lua` — adds five
  new cases (per "Proposed tests" above). No existing case is
  altered.
- Edited: parent `issue.md` — records the resolution of three
  deferred shape decisions (abort, `range`, synthesized_notify)
  with rejection reasons for the alternatives. Updates the
  Spec-row schema sketch to include `range`, the abort-tuple
  return from `args`, and the new `kind` value.
- Unchanged: `lua/utils/obsidian_cli/` (any file).
- Unchanged: `lua/utils/wordcount.lua`.
- Unchanged: `lua/colors/solarized.lua`.
- Unchanged: `tests/init.lua`, `tests/run`, all other specs.
- New: this sub-issue's `aar.md` on close.

## Dependencies

- **#23 closure** — `commands.register` exists at
  `lua/config/commands_registrar.lua` with the spec-row schema
  baseline. Already closed.
- **#24 closure** — established the per-row migration pattern.
  Already closed.
- **#25 closure** — established the registrar-extension pattern
  (one new spec-row key per sub-issue, with corresponding new
  spec cases). This sub-issue applies the same pattern for
  `range` (mechanical mirror of `nargs`). Already closed.
- **#26 closure** — established the `kind`-discriminated branch
  pattern (`kind = "void"` plus the registrar-callback ordering
  `pcall(require)` → `args` → kind branches → default envelope).
  This sub-issue extends `kind`'s enum by one value
  (`"synthesized_notify"`) following the same pattern. Already
  closed.
- **`utils.obsidian_cli`** — public surface
  (`search_context_to_quickfix`, `wordcount_current`) is the
  registration target for two of the three rows. Cycle PRD
  non-goal: no edits in this cycle.
- **`utils.wordcount`** — public surface
  (`buf_line_range_wordcount`) is the registration target for
  `WordCount`. Cycle PRD non-goal: no edits in this cycle.
- **Cycle 01 closure** — `mini.test` harness at `./tests/run`.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `27-search-and-wordcount-rows`
  tracks GitHub issue #27.
- No dependency on any other cycle 03 sub-issue beyond #23, #24,
  #25, #26.

## Out of scope (deferred to subsequent sub-issues of parent #22)

- `complete` and `bang` forwarding to the registrar. No consumer
  in cycle 03. Lands when one needs it.
- `notify`-returns-nil skip-the-notify path. No production row
  uses it; adding the case adds untested-in-production surface.
  Lands with the first row that needs it.
- Hardening the registrar against missing-`fn` calls (carried
  forward from #24's AAR flag). Not in scope here. If surfaced
  by the live smoke check, becomes a parent #22 flag, not a fix
  in this sub-issue.
- Generalising the abort tuple to non-`args` callers (e.g., a
  `validate` field that runs after `args` and may also abort).
  Current shape — `args` may abort — is sufficient for every
  command in `commands.lua` after this migration.
- Domain-language additions to `ubiquitous-language.md`. The new
  terms — *abort tuple*, *synthesized notify*, *void return* —
  are pattern-language for the registrar's interface, not domain
  vocabulary. Same exclusion rationale as #26.
- Candidate F (domain split of `commands.lua`) decision. Closing
  sub-issue of parent #22.
- ADR-0004 candidacy for the registrar pattern. Per cycle PRD
  open question 4, deferred until at least one more seam
  (Candidate B or D) is in place. After this sub-issue, the
  registrar's full shape is visible (default envelope + `void` +
  `synthesized_notify` + abort + `nargs` + `range` forwards) —
  enough surface for an ADR if cycle 03 chooses to write one,
  but the decision still belongs to the closing sub-issue or
  the cycle close.
