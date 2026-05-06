# Parent Issue — macOS `codesign` workaround extraction (Candidate D)

GitHub issue: #30. Second parent of cycle `03-config-deepening`,
landing second per the cycle PRD's resolved sequencing (A → D → B → C).
Translates `sub-prd.md` into a trackable technical unit. The two
artifacts are complementary — `sub-prd.md` records product-level intent
(user stories, scope, dependencies); this file records the technical
contract (acceptance criteria, implementation approach, flags).

## Acceptance criteria

- [x] `lua/utils/macos_codesign/` exists as a subpackage directory
      containing at minimum `command.lua`, `shell.lua`, and `init.lua`.
      Follows the ADR-0003 four-layer layout; parser and presenter layers
      are omitted (no output parsed; notifications are the utility's
      responsibility, not a presenter's).
- [x] `command.lua` exposes `M.resign_command(lazy_path: string) →
      string` — a pure function returning the `find … -exec codesign …`
      shell command string. No side effects. No `vim.*` dependencies.
      Verified by a unit test asserting the returned string for a known
      path.
- [x] `shell.lua` exposes `M.run(cmd: string)` and a setter seam
      (`M.set_runner(fn)` / `M.reset_runner()`) following the ADR-0003
      pattern. The default runner executes the command (synchronously,
      via the same mechanism as the current `io.popen`-based
      implementation). Tests substitute a fake runner to verify `run` is
      called with the expected command string.
- [x] `init.lua` exposes `M.resign_lazy_plugins()`:
      1. Guards on `vim.fn.has("mac") == 1`; returns early on non-macOS.
      2. Derives `lazy_path` from `vim.fn.stdpath("data") .. "/lazy"`.
      3. Calls `command.resign_command(lazy_path)` to build the command.
      4. Emits an INFO `vim.notify` before running.
      5. Calls `shell.run(cmd)`.
      6. Emits an INFO `vim.notify` after running.
- [x] At least one unit test exists under `tests/utils/macos_codesign/`
      exercised by `./tests/run`. The test fakes the shell runner seam,
      calls `resign_lazy_plugins()` (with macOS guard satisfied), and
      asserts the runner was called with a command string containing
      `find`, `*.so`, and `codesign`.
- [x] The autocmd block in `lua/config/autocmds.lua` (lines 123–144)
      is replaced with an unconditional `autocmd("User", { … })` whose
      callback is a one-line call:
      `require("utils.macos_codesign").resign_lazy_plugins()`.
      The `if vim.fn.has("mac") == 1 then … end` wrapper is removed from
      `autocmds.lua`; the guard lives inside `resign_lazy_plugins()`.
- [x] No edits to any other autocmd handler in `lua/config/autocmds.lua`.
      Verified by `git diff` showing changes only to the codesign block
      and nothing else in the file.
- [x] `./tests/run` exits 0 on the whole suite — including all cycle 01,
      cycle 02, and cycle 03 (parent #22) specs.
- [x] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `codesign` and `obsidian` absent from `$PATH`).
- [x] No reaching into local functions or monkey-patching internals in
      the new specs. Carry-forward acceptance criterion from cycles 01–02
      and parent #22, still binding. The shell-runner setter seam is the
      only sanctioned substitution point.
- [x] **Resolved-through-implementation decision recorded:** the
      `has("mac")` guard lives in `init.lua` (inside
      `resign_lazy_plugins()`), not in `autocmds.lua`. Reason: the
      autocmd should be unconditional and declarative — the guard is
      application logic that belongs in the utility, not in the wiring
      file. See `aar.md`.

## Implementation approach

### Four-layer layout (per ADR-0003)

```
lua/utils/macos_codesign/
  command.lua   — pure: M.resign_command(lazy_path) → string
  shell.lua     — impure: M.run(cmd), M.set_runner, M.reset_runner
  init.lua      — composition root: M.resign_lazy_plugins()
```

No `parsers.lua` (output discarded). No `presenter.lua` (notifications
sent directly from `init.lua`; there is no Neovim-buffer presentation).

### `command.lua`

```lua
local M = {}

function M.resign_command(lazy_path)
  return string.format(
    "find %s -name '*.so' -exec codesign -f -s - {} \\; 2>&1",
    lazy_path
  )
end

return M
```

Pure, independently `require`-able, no seam needed. The format string
matches the current inline implementation exactly.

### `shell.lua`

```lua
local M = {}

local default_runner = function(cmd)
  local handle = io.popen(cmd)
  if handle then handle:close() end
end

local runner = default_runner

function M.run(cmd)
  runner(cmd)
end

function M.set_runner(fn)
  runner = fn
end

function M.reset_runner()
  runner = default_runner
end

return M
```

Setter seam follows ADR-0003. Default runner preserves the current
`io.popen` + discard behavior. Tests inject a recording function to
assert the command string without shelling out.

### `init.lua`

```lua
local M = {}

function M.resign_lazy_plugins()
  if vim.fn.has("mac") ~= 1 then return end
  local command = require("utils.macos_codesign.command")
  local shell   = require("utils.macos_codesign.shell")
  local lazy_path = vim.fn.stdpath("data") .. "/lazy"
  vim.notify("Re-signing plugin .so files for macOS compatibility...", vim.log.levels.INFO)
  shell.run(command.resign_command(lazy_path))
  vim.notify("Done re-signing .so files.", vim.log.levels.INFO)
end

return M
```

### Autocmd wiring (post-extraction)

```lua
-- macOS 26+ (Tahoe): re-sign .so files after lazy plugin changes.
autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyBuild" },
  callback = function()
    require("utils.macos_codesign").resign_lazy_plugins()
  end,
  desc = "Re-sign plugin .so files for macOS compatibility after Lazy updates",
})
```

The `if vim.fn.has("mac") == 1 then … end` wrapper is gone from
`autocmds.lua`. The guard lives inside `resign_lazy_plugins()`, making
the autocmd unconditional and declarative.

### Deferred decisions

**`io.popen` vs `vim.fn.jobstart`:** The current implementation uses
synchronous `io.popen`. Switching to async `vim.fn.jobstart` would
prevent blocking on large plugin directories but introduces callback
complexity and a different notification flow. Deferred: the synchronous
path matches current observable behavior; async is a future cycle's call
if blocking proves a problem.

**Error surfacing from `codesign`:** Current implementation discards
exit code and output. A future cycle could surface errors if `codesign`
fails (e.g., permission denied, not found). Not in scope here.

### Test pattern

Adapts the fake-the-API pattern from parent #22 to the shell-adapter
seam:

1. In `pre_case`, call `shell.set_runner(fake)` where `fake` records
   the command string.
2. Call `resign_lazy_plugins()` with a stubbed `vim.fn.has` and
   `vim.fn.stdpath`.
3. Assert the fake runner received a string containing `find`, `*.so`,
   `codesign`.
4. In `post_case`, call `shell.reset_runner()`.

`vim.fn.has` and `vim.fn.stdpath` can be swapped in the test's
`pre_case` the same way `vim.api.nvim_create_user_command` was swapped
in parent #22's specs — assign a fake into the `vim.fn` table for the
duration of the test case.

### Sequencing

**No sub-issues.** The interface, sketches, and both design decisions
are fully specified in this `issue.md`. No shape decision is deferred to
discovery during implementation. Implementation proceeds directly from
this file: build the three layers, write the specs, wire `autocmds.lua`,
check off ACs as each verification passes. Parent #30 closes with this
`issue.md` (ACs checked) and a sibling `aar.md`. The next GitHub issue
number (#31) belongs to the next parent issue in the cycle.

### Constraints binding the implementation

1. No edits to any autocmd handler in `autocmds.lua` other than the
   codesign block (lines 123–144).
2. No new public API beyond `resign_lazy_plugins()`. The utility is
   single-consumer (the one autocmd callback).
3. Tests exercise public interfaces only — `resign_lazy_plugins()` via
   `init.lua`, `resign_command` via `command.lua` directly. No
   reaching into `shell.lua` locals beyond the setter seam.
4. The suite runs green with `codesign` absent from `$PATH`. The
   shell-runner seam ensures the test never invokes the real binary.
5. No new plugin dependencies. `mini.test` remains the only test
   tooling.

## Dependencies

- **Cycle 01 closure** — `mini.test` harness at `./tests/run`. Already
  closed.
- **Cycle 03 parent #22 (A) closure** — test pattern (fake-the-API
  seam) proven. Already closed.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `30-macos-codesign` tracks GitHub issue
  #30; sub-issues take sequential GitHub numbers.
- **ADR-0003** — four-layer subpackage layout. Binding for this parent.
- No dependency on parents B or C.

## Flags

*None yet. Sub-issue AARs surface flags as they appear.*
