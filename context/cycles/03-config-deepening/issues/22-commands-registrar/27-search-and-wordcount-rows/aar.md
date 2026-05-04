# AAR — Sub-issue #27: Search and WordCount rows

## What was built

Three registrar shape decisions resolved and three commands migrated:

| Command | New shape | Registrar change |
| --- | --- | --- |
| `ObsCLISearchContext` | abort-from-`args` (WARN on empty prompt) | abort-tuple inspection |
| `WordCount` | `range` forwarding + `kind = "synthesized_notify"` | `opts.range` conditional + new `kind` branch |
| `ObsCLIWordCount` | existing surface (`nargs = "*"`, `args` parsing) | none new |

`lua/config/commands.lua` now contains zero direct `vim.api.nvim_create_user_command`
calls and zero direct `pcall(require, "utils.obsidian_cli")` or
`pcall(require, "utils.wordcount")` calls. All 18 user commands are
registered through `commands.register`.

## Registrar diffs

**1. Abort branch** — `spec.args` evaluation changed from
`local args = spec.args and spec.args(cmd_opts) or {}` to an explicit
`if spec.args then ... end` block to correctly capture the multi-value
abort tuple `(nil, msg, level)`. The `and/or` ternary idiom in Lua
collapses the multi-return through short-circuit evaluation (the first
`nil` return triggers the `or {}` fallback), so the explicit form is
required. After evaluation, one new guard:

```lua
if args_table == nil and abort_msg ~= nil then
  vim.notify(abort_msg, abort_level or vim.log.levels.WARN)
  return
end
```

**2. `range` forwarding** — one line added adjacent to the existing
`nargs` conditional:

```lua
if spec.range ~= nil then opts.range = spec.range end
```

**3. `kind = "synthesized_notify"` branch** — added between the `void`
branch and the default `(success, msg)` envelope:

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

## Line-count delta

`lua/config/commands.lua`: 274 lines → 256 lines (−18 net).
Three inline blocks (≈78 lines removed) replaced by three `register()`
calls (≈60 lines added). The `ObsCLIWordCount` args function is the
longest at ~22 lines; the search and wordcount calls are compact.

## Implementation note: multi-value return and Lua `and/or`

The sub-issue's interface-design sketch used
`local args_table, abort_msg, abort_level = spec.args and spec.args(cmd_opts) or {}`.
This does not work: in `a and f() or {}`, the `and` operator adjusts `f()`'s
multi-return to one value for the truthiness check, so a `nil` first return
triggers the `or {}` fallback and the abort tuple is lost. The correct form
assigns via an explicit `if spec.args then ... end` block, which preserves
all return values. The sketch was an approximation; this note records the
distinction.

## Deliberate-failure verifications

**DFV1 — Abort branch above `pcall(require)`.**
Manual reasoning: the abort tests use `package.loaded` stubs so they don't
depend on `pcall` succeeding. Moving the abort check above `pcall` would
leave the abort tests green; load-failure cases would still fire ERROR
because `spec.args` is nil for those specs (so `args_table = {}`, not nil,
meaning the abort branch never fires). The pipeline ordering is still
correct as designed: pcall first ensures the module exists before
evaluating args. No code change; correct ordering retained.

**DFV2 — `synthesized_notify` branch above `pcall(require)`.**
Temporary mutation: moved the `synthesized_notify` branch before
`pcall(require)` with `mod = nil`. Result: both
`register: kind = "synthesized_notify" calls notify with leaf returns and emits one notify`
and
`register: kind = "synthesized_notify" still surfaces load failure as ERROR notify`
went red with `attempt to index local 'mod' (a nil value)`. Confirms the
load-failure guard at the top of the callback is load-bearing for all
`kind` branches; each branch must run after `pcall`. Reverted.

## Live smoke check

Verified in Neovim:

| Scenario | Result |
| --- | --- |
| `:ObsCLISearchContext` with empty input (just Enter) | WARN notify "Search query required.", no quickfix population |
| `:ObsCLISearchContext` with non-empty query | quickfix populated with matching notes |
| `:WordCount` (cursor on line N) | INFO notify "N words (lines N–N)" |
| `:'<,'>WordCount` (visual range) | INFO notify with selected range word count and correct line numbers |
| `:%WordCount` | INFO notify with whole-buffer word count |
| `:ObsCLIWordCount` (no args) | leaf called with `{ path_rel = nil, mode = "full" }` |
| `:ObsCLIWordCount words` | leaf called with `{ path_rel = nil, mode = "words" }` |
| `:ObsCLIWordCount path/to/note.md` | leaf called with `{ path_rel = "path/to/note.md", mode = "full" }` |
| `:ObsCLIWordCount path/to/note.md chars` | leaf called with `{ path_rel = "path/to/note.md", mode = "characters" }` |

All eight scenarios match pre-migration behavior.

## Test results

- New cases: 6 (abort with level, abort default WARN, range forwards,
  range omits when nil, synthesized_notify emits notify, synthesized_notify
  load failure).
- Inherited cases: 12 (7 from #23, 2 from #25, 3 from #26) — all unchanged.
- Total registrar spec: 18 cases, all passing.
- Full suite: 110 cases, 0 failures.
- Suite passes with `obsidian` absent from `$PATH`.

## Flags for closing sub-issue

None. The registrar's full shape is now visible:
`pcall(require)` → `args` (with abort tuple) → `kind = "void"` branch →
`kind = "synthesized_notify"` branch → default `(success, msg)` envelope.
The Candidate F decision (domain split of `commands.lua` or skip) is the
sole remaining work in parent #22. The question of whether to write
ADR-0004 for the registrar pattern belongs to the closing sub-issue.
