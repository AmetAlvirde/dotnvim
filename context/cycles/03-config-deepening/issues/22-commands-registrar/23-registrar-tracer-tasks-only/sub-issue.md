# Sub-issue — Registrar tracer + `ObsCLITasks` migration

GitHub issue: #23. First sub-issue of parent #22. The Stage-1 tracer
slice for Candidate A: stand up `commands.register(spec)` in its
chosen location, prove via specs that it registers correctly and
handles every observable branch of the per-command callback shape,
migrate exactly one user command (`ObsCLITasks`) onto the seam, and
leave the other 17 commands and the leaf modules untouched. No
parser, no presenter, no `mini.test.new_child_neovim`. The slice is
the test pattern Candidates B and D will inherit, demonstrated end
to end against the smallest possible call site.

## Description

Build a `commands.register(spec)` function in
`lua/config/commands_registrar.lua` (location decision made under
"Interface design" below; revisited in this sub-issue's AAR if the
implementation surfaces a second consumer). The registrar takes a
spec table and registers one user command via
`vim.api.nvim_create_user_command`. The registered callback
encapsulates the `pcall(require, ...)` → call → `vim.notify` shape
that is currently repeated 14 times across `commands.lua`.

In `lua/config/commands.lua`, replace the existing `ObsCLITasks`
block (lines 21–36) with one spec-row call to `commands.register`.
The other 17 user commands stay on their existing inline shape — they
migrate in subsequent sub-issues, grouped by argument-shape similarity.

Add `tests/config/commands_registrar_spec.lua` covering:

- the call shape passed to a faked `vim.api.nvim_create_user_command`
- `pcall(require)` failure emits one ERROR-level `vim.notify` and
  returns
- leaf returning `(true, "")` or `(true, nil)` emits no notify
- leaf returning `(false, msg)` emits one ERROR-level
  `vim.notify(msg)`
- leaf returning `(true, msg)` with non-empty `msg` emits one
  INFO-level `vim.notify(msg)`

A deliberate-failure verification (rename `tasks_to_quickfix` on the
fake leaf, confirm the spec goes red, revert) runs once during
implementation and is recorded in the AAR. Not a committed spec.

`mini.test.new_child_neovim` is not used. The registrar is a pure
transformation from spec to recorded `nvim_create_user_command` call
plus a callback whose branches are exercised through stubbed
collaborators.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `vim.api.nvim_create_user_command` | In-process (Neovim API) | Replaced in `pre_case` with a fake that records `(name, callback, opts)` into a per-test table; restored in `post_case`. The seam is the one-and-only place this API is called from configuration code after the migration; the swap is targeted and test-local. |
| `vim.notify` | In-process (Neovim API) | Replaced in `pre_case` with a fake that records `(msg, level)`; restored in `post_case`. |
| `pcall` / `require` | In-process (Lua stdlib) | Load-failure branch exercised by registering against a deliberately non-existent module name (`utils.does_not_exist`). No monkey-patching of `require` itself. |
| `utils.obsidian_cli` (the leaf module) | In-process (consumer-side, owned) | The leaf-call branches are exercised by registering against a tiny test module the spec creates under `package.loaded` — this avoids reaching into `utils.obsidian_cli` and avoids depending on its real behavior. The migrated `ObsCLITasks` row in `commands.lua` continues to register against the real `utils.obsidian_cli` at runtime. |
| `mini.test` | In-process (test runner) | Loaded via cycle 01's harness. Spec runs through `./tests/run`. |
| `tests/init.lua` bootstrap | In-process | Carry-forward from cycle 01. The new spec lives under `tests/config/`; bootstrap's `os.exit(0)` short-circuit applies unchanged. |

The seam being introduced (`commands.register`) has two justified
adapters of `vim.api.nvim_create_user_command`: the production binding
(the real Neovim API) and the test fake. Seam discipline check passes.

## Interface design

Two design alternatives. Alternative C (experience-heavy) is not
applicable here — this is mechanism work, not encounter-shaping.

### Alternative A — Single uniform `commands.register(spec)`

```lua
-- spec keys (final shape closed in this sub-issue):
-- name           string, required, forwarded to nvim_create_user_command
-- desc           string, required, becomes opts.desc
-- module         string, required, the leaf to require
-- fn             string, required, the key on the required module
-- args           function(opts) -> table | nil, optional; default {}
-- on_load_error  string, optional; defaults to "Failed to load " .. module
--
-- Optional forwards (added in subsequent sub-issues as commands needing
-- them migrate; the tracer's row uses none of these):
-- nargs          forwarded to opts
-- complete       forwarded to opts
-- range          forwarded to opts
-- bang           forwarded to opts
local function register(spec)
  local opts = { desc = spec.desc }
  -- (nargs/complete/range/bang forwards land in subsequent sub-issues)
  vim.api.nvim_create_user_command(spec.name, function(cmd_opts)
    local ok, mod = pcall(require, spec.module)
    if not ok then
      vim.notify(spec.on_load_error or ("Failed to load " .. spec.module),
                 vim.log.levels.ERROR)
      return
    end
    local args = spec.args and spec.args(cmd_opts) or {}
    local success, msg = mod[spec.fn](unpack(args))
    if not success then
      vim.notify(msg, vim.log.levels.ERROR)
      return
    end
    if msg and msg ~= "" then
      vim.notify(msg, vim.log.levels.INFO)
    end
  end, opts)
end
```

One entry point. Every user command — ObsCLI, Solarized, WordCount —
flows through this same shape. The Solarized commands need a separate
treatment (their leaves return nothing, not `(success, msg)`); that
decision is deferred to the sub-issue that migrates them. For the
tracer, the spec the registrar accepts is the shape above, and
`ObsCLITasks` fits it directly.

### Alternative B — Convenience wrapper for `obsidian_cli`

```lua
-- Specialized for the dominant caller — utils.obsidian_cli with the
-- standard (success, msg) envelope.
local function register_obscli(name, leaf_fn_name, desc, args_fn)
  return register({
    name = name,
    desc = desc,
    module = "utils.obsidian_cli",
    fn = leaf_fn_name,
    args = args_fn,
  })
end
```

13 of 18 rows omit the `module = "utils.obsidian_cli"` boilerplate and
the `fn = "..."` key name. Saves ~13 lines across `commands.lua`.

### Comparison

- **Leverage.** A's single entry point is the seam the parent issue's
  user story 1 mandates ("register it as one row"). B adds a second
  entry point that solves a typing concern, not an architectural one.
- **Locality.** With A, every command is registered through the same
  named function — a maintainer auditing user-command surface greps
  for one symbol. B splits the audit between `register` and
  `register_obscli`.
- **Testability.** A requires one test surface; B requires two
  (the convenience wrapper has its own delegation behavior to verify).
  Parent issue AC 5 ("at least one passing unit test for the
  registrar") is cleaner against A.
- **Future-proofing.** A scales to Candidates B and D's seams without
  precedent: each new seam is its own `register` function for its own
  domain. B sets the precedent that domains earn convenience wrappers,
  which is real architectural debt for a 13-line saving.

### Chosen: A

Reason for rejecting B: B's only benefit is keystrokes saved on the
13 ObsCLI rows. The cost is a second entry point that breaks the "one
declarative list, one registration mechanism" promise. The right time
to add a convenience wrapper is when a second domain needs the same
shape (it does not, in this configuration).

### Location decision (resolves cycle PRD open question 2)

`lua/config/commands_registrar.lua` — co-located with `commands.lua`.
The two other options from the parent issue:

- **Local table inside `commands.lua`:** rejected. The whole point of
  the seam is that it is `require`-able and unit-testable in isolation.
  A local would be a private-by-convention seam that the spec cannot
  exercise without monkey-patching `commands.lua`'s top-level state.
- **Promoted to `lua/utils/`:** rejected for now. Promotion is
  warranted only when a second consumer surfaces. There is no second
  consumer in cycle 03's scope. If Candidate B's `colors.solarized.subscribe`
  ends up wanting the same registrar shape, that promotion happens in
  Candidate B's sub-issues, not pre-emptively here.

Recorded in parent `issue.md` as the resolved-through-implementation
decision once this sub-issue closes.

### Entry points, inputs, outputs, invariants, error modes

- **Entry point:** `commands.register(spec)`.
- **Input:** spec table with the keys above. Required keys: `name`,
  `desc`, `module`, `fn`. Optional in the tracer: `args`, `on_load_error`.
- **Output:** none. The function's effect is one
  `vim.api.nvim_create_user_command` call.
- **Invariant 1:** the function calls `nvim_create_user_command`
  exactly once per `register` call. No retries, no late binding, no
  caching.
- **Invariant 2:** the registered callback never throws. Every error
  path surfaces through `vim.notify` and returns; no `error()` raised
  from inside the callback under any of the five branches.
- **Invariant 3:** when `msg` is `nil` or `""` on a success return, no
  notify happens — silence is part of the contract, not a bug.
- **Error mode 1 (load failure):** `pcall(require, spec.module)`
  returns false → ERROR-level `vim.notify`, return.
- **Error mode 2 (leaf failure):** leaf returns `(false, msg)` →
  ERROR-level `vim.notify(msg)`, return.
- **Error mode 3 (leaf success with message):** leaf returns
  `(true, msg)` with non-empty `msg` → INFO-level `vim.notify(msg)`.
- **Error mode 4 (leaf success silent):** leaf returns `(true, "")` or
  `(true, nil)` → no notify.

## Acceptance criteria

- [ ] `lua/config/commands_registrar.lua` exists and exposes
      `M.register(spec)`. The module is `require`-able as
      `require("config.commands_registrar")`.
- [ ] `lua/config/commands_registrar.lua` is the only file under
      `lua/config/` that calls `vim.api.nvim_create_user_command`.
      Verified by
      `grep -n 'nvim_create_user_command' lua/config/commands_registrar.lua`
      returning at least one match and
      `grep -rn 'nvim_create_user_command' lua/config/ --exclude=commands_registrar.lua`
      returning zero matches *for the migrated `ObsCLITasks` only*.
      The other 17 commands still match here — that is expected and
      cleared in subsequent sub-issues.
- [ ] In `lua/config/commands.lua`, the previous `ObsCLITasks` block
      (the `vim.api.nvim_create_user_command("ObsCLITasks", function() ... end, ...)`
      spanning the lines that hold the `pcall(require, "utils.obsidian_cli")`
      → call → notify shape) is replaced by exactly one
      `commands.register({ ... })` call with the spec row for
      `ObsCLITasks`.
- [ ] The 17 other user commands in `commands.lua` are byte-for-byte
      unchanged from the cycle base. Verified by `git diff` showing
      edits only in the `ObsCLITasks` block plus the new `local
      register = require("config.commands_registrar").register` line
      (or equivalent require alias).
- [ ] `tests/config/commands_registrar_spec.lua` exists and passes
      under `./tests/run`. The spec covers all five branches listed
      under "Proposed tests" below.
- [ ] At least one of the five branches is exercised against a
      stub leaf module placed into `package.loaded` by the spec.
      No reaching into `utils.obsidian_cli` internals; no
      monkey-patching `require` itself.
- [ ] `vim.api.nvim_create_user_command` and `vim.notify` are swapped
      via `pre_case` and restored via `post_case` (or
      `mini.test.finally`). No global mutation persists across cases.
- [ ] `./tests/run` exits 0 on the whole suite — including all cycle
      01 and cycle 02 specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `obsidian` and `codesign` absent from `$PATH`).
      The registrar spec must not require `utils.obsidian_cli` to
      load successfully.
- [ ] Manually invoking `:ObsCLITasks` inside Neovim continues to
      produce the same observable behavior as before the migration:
      a quickfix list of TODO tasks, or an ERROR-level notify on
      failure. Recorded in the AAR as a smoke check, not a spec.
- [ ] No reaching into local functions or monkey-patching internals
      anywhere in the new spec. Carry-forward acceptance criterion
      from cycles 01 and 02.
- [ ] AAR records: the registrar location decision (chosen here),
      the spec-row schema decision (chosen here), the deliberate-
      failure verification result, and any flags for subsequent
      sub-issues to inherit.

## Proposed tests

| Title | What it verifies |
| --- | --- |
| registers via `nvim_create_user_command` with the expected name and `opts.desc` | Spec row → API call shape. The `name` and `desc` keys round-trip into the recorded `(name, callback, opts)` tuple. |
| invokes the registered callback when triggered | The callback recorded by the API fake is invocable and runs the inner `pcall` → call → notify pipeline. |
| load failure path: missing module triggers one ERROR notify and returns | Spec registers against `module = "utils.does_not_exist"`, invokes the callback, asserts exactly one `vim.notify` recorded at ERROR level with the load-error message. |
| leaf returns `(true, "")`: no notify | Spec registers against a stub leaf in `package.loaded`, invokes the callback, asserts zero `vim.notify` calls recorded. Same case for `(true, nil)`. |
| leaf returns `(false, msg)`: one ERROR notify with `msg` | Stub leaf returns `(false, "boom")`; assert exactly one `vim.notify("boom", ERROR)`. |
| leaf returns `(true, msg)` with non-empty `msg`: one INFO notify with `msg` | Stub leaf returns `(true, "loaded 4 items")`; assert exactly one `vim.notify("loaded 4 items", INFO)`. |

The first two are the Stage-2 First Contact pair (the seam exists and
is wired). The remaining four exercise the four branches of the
callback's observable contract. Six cases total — the minimum that
covers every error mode declared under "Interface design" above.

A deliberate-failure verification is run once during implementation
(stub leaf returns `(false, "boom")`, swap the registrar's
`vim.log.levels.ERROR` to `INFO`, confirm the ERROR-branch case goes
red, revert) and recorded in the AAR. Not a committed spec.

## Affected artifacts

- New: `lua/config/commands_registrar.lua`
- New: `tests/config/commands_registrar_spec.lua`
- Edited: `lua/config/commands.lua` — only the `ObsCLITasks` block
  (and one new `local register = require(...)` line at the top of
  the file).
- Unchanged: `lua/utils/obsidian_cli/` (any file).
- Unchanged: `lua/colors/solarized.lua`.
- Unchanged: `lua/utils/wordcount.lua`.
- Unchanged: `tests/init.lua`, `tests/run`, all existing specs.

## Dependencies

- **Cycle 01 closure** — `mini.test` harness in place at
  `./tests/run`. Already closed.
- **Cycle 02 closure (parent #13)** — `lua/utils/obsidian_cli/init.lua`
  exposes `tasks_to_quickfix(opts)` with the `(success, msg)` return
  envelope. Already closed; verified by inspection at the migration
  call site.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `23-registrar-tracer-tasks-only` tracks
  GitHub issue #23.
- **Parent #22** — this sub-issue closes the registrar-location and
  spec-row-schema resolve-through-implementation items the parent
  carries. Both decisions are recorded in parent `issue.md` once this
  sub-issue lands green.
- No dependency on any other cycle 03 sub-issue. This is the first
  sub-issue of the first parent.

## Out of scope (deferred to subsequent sub-issues of parent #22)

- Migration of the other 17 user commands. They stay on their
  existing inline `nvim_create_user_command` shape until subsequent
  sub-issues group them by argument-shape similarity.
- The `nargs` / `complete` / `range` / `bang` opts forwarding. The
  tracer's row (`ObsCLITasks`) uses none of these. Forwarding is
  added when the first command needing one of them migrates.
- The Solarized void-return shape decision. `set_theme("dark")` and
  `toggle()` do not return `(success, msg)`. The shape used to model
  these — variant spec, separate `register_void`, or thin
  `(true, "")` adapter — is decided when those rows migrate.
- The Candidate F (domain split of `commands.lua`) decision. Closing
  sub-issue of parent #22.
- Generalizing the registrar to `lua/utils/`. Deferred until a second
  consumer surfaces.
- ADR-0004 candidacy for the registrar pattern. Per cycle PRD open
  question 4, deferred until at least one more seam (Candidate B or D)
  is in place.
