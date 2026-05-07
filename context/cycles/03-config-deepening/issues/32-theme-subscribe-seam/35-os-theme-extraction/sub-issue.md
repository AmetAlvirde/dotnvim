# Sub-issue #35 — `os_theme` extraction (Candidate E)

GitHub issue: #35. Third sub-issue under parent #32 (Candidate B —
theme-change subscribe seam) of cycle `03-config-deepening`.

## Description

Extract the inlined `get_os_theme` local function in
`lua/colors/solarized.lua` (currently lines 55–76) into a sibling
module `lua/colors/os_theme.lua`. The new module exposes
`M.detect() -> "dark" | "light"`, follows ADR-0003's setter-seam
shape (`M.set_runner(fn)` / `M.reset_runner()`), and caches the last
detected value. Cache invalidation is an explicit entry point —
`M.refresh()` — so callers (and a future `FocusGained` reshape in
#36) can opt into a fresh OS read. The default runner shells out
via `io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")`
on macOS, mirroring the production behavior of `get_os_theme`. On
Linux, the existing `gsettings` branch is preserved. On other
systems, the `vim.o.background`-derived fallback survives unchanged.

`solarized.setup()` swaps its single call site —
`local theme = theme_override or get_os_theme()` (line 126) —
for `local theme = theme_override or require("colors.os_theme").detect()`,
and the inlined `get_os_theme` is deleted. No other surface in
`solarized.lua` is touched.

The `FocusGained` and `VimEnter` solarized autocmds in
`lua/config/autocmds.lua` (lines 104–121) are NOT touched in this
sub-issue. Their disposition (retain-with-reason vs collapse,
whether to call `os_theme.refresh()` before re-running `setup()`)
is the closing sub-issue #36's call, informed by how the cache
behaves under the actual `FocusGained` flow.

After this sub-issue:

- `lua/colors/os_theme.lua` exists with `M.detect`, `M.refresh`,
  `M.set_runner`, `M.reset_runner`. The module is publicly
  `require`-able.
- `lua/colors/solarized.lua` no longer defines a local
  `get_os_theme` function. `M.setup`'s body reads
  `os_theme.detect()` for the no-override path.
- `tests/colors/os_theme_spec.lua` exists and exercises:
  runner-seam delivery on a cache miss, cache hit on the second
  call, `M.refresh()` invalidation, OS-branch routing via a
  `vim.fn.has` stub, and the `vim.o.background` fallback when no
  OS branch matches.
- `tests/colors/solarized_subscribe_spec.lua` continues to pass:
  its `pre_case` learns to clear `package.loaded["colors.os_theme"]`
  alongside `package.loaded["colors.solarized"]`, so per-case cache
  state does not leak across the seven existing cases.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `vim.fn.has` | True external (Neovim API) | Per-test stub returning 0/1 to route the OS branch. Established pattern from `solarized_subscribe_spec.lua`. |
| `io.popen` (default runner only) | True external (shell adapter) | Replaced in tests via `M.set_runner(fake_fn)`. The default runner is never invoked under test. Mirrors parent #30's `macos_codesign.shell` pattern. |
| `vim.o.background` | True external (Neovim runtime state) | Tests assign directly in `pre_case`; reads in the fallback branch are unmocked. |
| `package.loaded` | In-process (Lua module cache) | Tests clear `package.loaded["colors.os_theme"]` in `pre_case` to force a fresh module load with empty cache state, matching `solarized_subscribe_spec.lua`'s pattern. |
| `colors.solarized` (caller) | In-process | Already exercised by `solarized_subscribe_spec.lua`. After the swap, that spec is the integration check that `solarized.setup()` correctly delegates to `os_theme.detect()`. |

No new ports. No new external dependencies. The runner seam is
the same shape parent #30 proved on `macos_codesign.shell`.

## Interface design

The public surface adds one module. Three internal questions.

1. **Layout** — collapse `os_theme` into a single file, or split
   per ADR-0003's four-layer pattern.
2. **Cache invalidation entry point** — `M.refresh()` (clears
   cache; next `detect()` reshells), `M.detect(force = true)`
   (in-call invalidation), or `M.invalidate()` (alias).
3. **Runner contract** — what does the runner return: raw stdout
   string (parsing inside `detect`), or the parsed
   `"dark"|"light"`?

### Question 1 — layout

#### Alternative A — single file `lua/colors/os_theme.lua` (collapsed)

```lua
-- lua/colors/os_theme.lua
local M = {}

local default_runner = function()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  return result
end

local runner = default_runner
local cached -- "dark" | "light" | nil

function M.set_runner(fn)   runner = fn end
function M.reset_runner()   runner = default_runner end
function M.refresh()        cached = nil end

function M.detect()
  if cached ~= nil then return cached end
  if vim.fn.has("mac") == 1 then
    local out = runner()
    cached = (out and out:match("Dark")) and "dark" or "light"
  elseif vim.fn.has("unix") == 1 then
    local out = runner()  -- gsettings command in default_runner if we keep this branch
    cached = (out and out:match("Dark")) and "dark" or "light"
  else
    cached = vim.o.background == "dark" and "dark" or "light"
  end
  return cached
end

return M
```

**Pros:** One file, one `require`. Matches the collapsed
precedent from parent #30 — when there is one shell command, one
trivial parser (a single `:match`), and no presenter, the four-layer
split adds folders without separating responsibilities. The runner
seam is directly visible at the top of the file. Short.

**Cons:** The `mac`-vs-`unix` runner-string difference (the
default runner has to choose between `defaults read` and
`gsettings get`) is awkward — either `default_runner` branches on
`vim.fn.has` itself (logic duplicated with `detect`), or
`detect` passes the command string to `runner(cmd)` (runner
becomes a thin `io.popen` wrapper, like `macos_codesign.shell.run`).
The latter is cleaner but starts to look like a half-step toward
ADR-0003.

#### Alternative B — submodule `lua/colors/os_theme/init.lua` + `shell.lua` (ADR-0003 split)

```
lua/colors/os_theme/
  init.lua    -- M.detect, M.refresh, cache, OS branching
  shell.lua   -- M.run(cmd), M.set_runner, M.reset_runner
```

```lua
-- lua/colors/os_theme/shell.lua  (mirrors macos_codesign.shell exactly)
local M = {}
local default_runner = function(cmd)
  local handle = io.popen(cmd)
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  return result
end
local runner = default_runner
function M.run(cmd)         return runner(cmd) end
function M.set_runner(fn)   runner = fn end
function M.reset_runner()   runner = default_runner end
return M
```

```lua
-- lua/colors/os_theme/init.lua
local shell = require("colors.os_theme.shell")
local M = {}
local cached
function M.refresh() cached = nil end
function M.detect()
  if cached ~= nil then return cached end
  if vim.fn.has("mac") == 1 then
    local out = shell.run("defaults read -g AppleInterfaceStyle 2>/dev/null")
    cached = (out and out:match("Dark")) and "dark" or "light"
  elseif vim.fn.has("unix") == 1 then
    local out = shell.run("gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null")
    cached = (out and out:match("Dark")) and "dark" or "light"
  else
    cached = vim.o.background == "dark" and "dark" or "light"
  end
  return cached
end
return M
```

Tests reach into `colors.os_theme.shell.set_runner` rather than
`colors.os_theme.set_runner`. Two `require` paths.

**Pros:** Mirrors `macos_codesign` exactly. The shell-execution
boundary is named in its own file. If a second `os_theme`-adjacent
utility ever needs the same `shell.run(cmd)` helper, it is already
factored.

**Cons:** Three files for what is currently one shell command and
one `:match`. The ADR-0003 precedent in parent #30 also split a
trivial command, but it had a semantic-grade `command.lua` (the
`find ... codesign -f -s -` invocation is non-obvious enough to
deserve a name). `os_theme`'s commands are one-liners that the
caller can read in place. Tests have to clear two
`package.loaded[...]` entries. The setter seam moves one `require`
hop away from the public surface.

#### Alternative C — single file with `runner(cmd)` signature

```lua
-- lua/colors/os_theme.lua
local M = {}
local default_runner = function(cmd)
  local handle = io.popen(cmd)
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  return result
end
local runner = default_runner
local cached

function M.set_runner(fn)   runner = fn end
function M.reset_runner()   runner = default_runner end
function M.refresh()        cached = nil end

function M.detect()
  if cached ~= nil then return cached end
  if vim.fn.has("mac") == 1 then
    local out = runner("defaults read -g AppleInterfaceStyle 2>/dev/null")
    cached = (out and out:match("Dark")) and "dark" or "light"
  elseif vim.fn.has("unix") == 1 then
    local out = runner("gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null")
    cached = (out and out:match("Dark")) and "dark" or "light"
  else
    cached = vim.o.background == "dark" and "dark" or "light"
  end
  return cached
end

return M
```

The runner takes `cmd` as an argument (matches
`macos_codesign.shell.run(cmd)`'s signature), so `default_runner`
doesn't need to know which OS we're on — the OS branching stays
in `detect`. The fake runner in tests inspects `cmd` if it wants to
assert which command would have been issued.

**Pros:** A's brevity with B's clean default-runner. The runner
seam carries a stable signature (`fn(cmd) -> stdout|nil`) shared
with `macos_codesign.shell.run`, which is a small uniformity win
across the configuration. One file. One `require`. Setter seam at
the top of the public surface.

**Cons:** Slightly more verbose than A's no-arg runner (but A's
runner had to internally branch, which is a worse trade). The
`detect` body still contains literal command strings; some readers
prefer those moved to a `command.lua`. Acceptable: the strings are
one-liners and naming them as `apple_interface_style_command()`
adds reading hops without adding meaning.

#### Chosen (proposed; final in AAR)

**Alternative C.** Single file, runner takes `cmd`.

**Reason for C:** Matches `macos_codesign.shell.run`'s signature
(stable runner contract across the configuration), avoids B's
folder-for-three-functions overhead, and avoids A's awkward
internal branching of `default_runner`. The collapse-vs-split
decision lands on collapse with a clean shell-runner contract,
honoring ADR-0003's *spirit* (named seam at the shell boundary)
without its full *form* (separate `shell.lua` file).

**Rejected A:** `default_runner` would either branch on `vim.fn.has`
(duplicating `detect`'s OS logic) or be unable to switch between
`defaults read` and `gsettings get`. The branching duplication is
the dealbreaker.

**Rejected B:** Three files for one shell command, one `:match`, no
presenter, no command-naming benefit. Sets a precedent that every
future shell-adjacent module must split, even when the split
yields three single-function files. Not what ADR-0003's
precedent in parent #30 was meant to communicate — parent #30 had
a non-obvious command worth naming; `os_theme` does not.

If implementation surfaces a reason to flip C→B (e.g. a second
caller wants `shell.run(cmd)` standalone, or the OS branching grows
beyond mac/unix/fallback), the AAR records the reason and the
resolution.

### Question 2 — cache invalidation entry point

Three options.

- **`M.refresh()`**: explicit no-arg invalidation. `os_theme.refresh()`
  reads at the call site as "ask the OS again next time". Pairs
  naturally with a future `FocusGained` autocmd in #36 calling
  `os_theme.refresh()` then `solarized.setup()`.
- **`M.detect(force = true)`**: in-call invalidation. Saves one
  call but couples the read with the invalidation; callers who want
  to re-detect later (not now) have nowhere to express that.
- **`M.invalidate()`**: synonym of `refresh()`. No new behavior.

**Chosen: `M.refresh()`.** The parent issue's sketch named it
`refresh`, the term reads correctly in the closing sub-issue's
likely usage (`os_theme.refresh()` inside the `FocusGained`
callback), and "refresh" is the verb used by Neovim's own
`vim.fn.systemlist`-adjacent patterns for cache-bypass entry
points. No alias needed.

### Question 3 — runner contract

Two options.

- **Runner returns raw stdout string (or nil).** `detect` parses.
  Pros: keeps parsing in one place, runner is a thin wrapper, fakes
  in tests can return crafted strings. Matches
  `macos_codesign.shell.run` (which returns nothing, but the
  read-from-handle pattern is identical).
- **Runner returns parsed `"dark"|"light"`.** `detect` just stores.
  Pros: smaller `detect` body. Cons: the parsing rule
  (`stdout:match("Dark") and "dark" or "light"`) escapes from the
  module into every test fake; a fake that returns a raw string
  would no longer test `detect`'s parser.

**Chosen: runner returns raw stdout string.** The parsing logic
lives in `detect`. Test fakes return raw strings (`"Dark\n"`,
`"\n"`, `nil`) and the `:match` parser is exercised on each call.
Matches the production `io.popen` contract one-to-one — the runner
is interchangeable with `io.popen(cmd):read("*a")` followed by
`:close()`.

### Public interface (post-sub-issue)

```lua
-- colors.os_theme  (new module)
M.detect()                -- returns "dark" | "light"; reads cache or calls runner
M.refresh()               -- clears cache; next detect() reshells
M.set_runner(fn)          -- fn(cmd) -> stdout_string | nil
M.reset_runner()          -- restores default_runner

-- colors.solarized  (no public-surface change)
M.setup(theme_override)   -- body change: get_os_theme deleted; calls os_theme.detect()
M.set_theme(theme)        -- unchanged
M.toggle()                -- unchanged
M.subscribe(fn)           -- unchanged
M.colors / M.dark_colors / M.light_colors  -- unchanged
```

## Acceptance criteria

- [x] `lua/colors/os_theme.lua` exists and is publicly
      `require`-able. Verified by
      `lua -e "package.path = './lua/?.lua;./lua/?/init.lua;' .. package.path; require('colors.os_theme')"`
      exiting 0 (or by the test suite green-bar).
- [x] `os_theme.detect()` returns `"dark"` or `"light"` for every
      execution path. Verified by spec cases covering: macOS
      branch (runner returns `"Dark\n"` → `"dark"`; runner returns
      `"\n"` → `"light"`; runner returns `nil` → `"light"`),
      Linux branch (gsettings stdout containing `"Dark"` →
      `"dark"`; otherwise `"light"`), fallback branch
      (`vim.o.background = "dark"` → `"dark"`;
      `vim.o.background = "light"` → `"light"`).
- [x] The default runner shells out via
      `io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")`
      on macOS and
      `io.popen("gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null")`
      on Linux, mirroring the current `get_os_theme` behavior
      verbatim (no command-string changes).
- [x] On a cache hit, `os_theme.detect()` returns the cached value
      without invoking the runner. Verified by a spec case that
      installs a counting fake runner, calls `detect()` twice, and
      asserts the runner was invoked exactly once.
- [x] `os_theme.refresh()` clears the cache. Verified by a spec
      case that calls `detect()` (runner invoked once),
      `refresh()`, then `detect()` again (runner invoked a second
      time; total invocations = 2).
- [x] `os_theme.set_runner(fn)` and `os_theme.reset_runner()` are
      module-level setters. The runner contract is
      `fn(cmd) -> stdout_string | nil`. Verified by spec cases
      that install and reset the fake.
- [x] `lua/colors/solarized.lua` no longer contains the local
      `get_os_theme` function. Verified by
      `grep -n 'function get_os_theme' lua/colors/solarized.lua`
      and `grep -n 'local function get_os_theme' lua/colors/solarized.lua`
      both returning zero matches.
- [x] `M.setup` in `lua/colors/solarized.lua` reads
      `local os_theme = require("colors.os_theme")` at the top of the
      file and calls `os_theme.detect()` in `M.setup`. Verified by
      reading the file.
- [x] `tests/colors/os_theme_spec.lua` exists and contains the
      cases enumerated under "Proposed tests" below. The spec
      uses the per-case fake-the-API pattern established by
      `solarized_subscribe_spec.lua`: `pre_case` clears
      `package.loaded["colors.os_theme"]` and stubs `vim.fn.has`;
      `post_case` restores `vim.fn.has` and clears the loaded
      module. No reaching into module-locals.
- [x] `tests/colors/solarized_subscribe_spec.lua`'s `pre_case` is
      extended to clear `package.loaded["colors.os_theme"]`
      alongside `package.loaded["colors.solarized"]`, preventing
      cache leakage across cases after the swap. All seven
      existing cases continue to pass.
- [x] `./tests/run` exits 0 on the whole suite. Total case count
      132 (125 + 7 new os_theme cases).
- [x] `PATH=/opt/homebrew/bin:/usr/bin:/bin ./tests/run` exits 0.
      The `os_theme` runner seam ensures no shell-out to `defaults`
      or `gsettings` during tests.
- [x] No reaching into local functions or monkey-patching
      internals beyond the sanctioned `os_theme.set_runner` /
      `os_theme.reset_runner` and per-test `vim.fn.has` swap. The
      `vim.api.nvim_set_hl`, `vim.cmd`, `vim.defer_fn` swaps from
      `solarized_subscribe_spec.lua` are not needed in
      `os_theme_spec.lua` — `detect()` does not invoke them.
      (Carry-forward.)
- [x] **Resolved-through-implementation decision recorded in AAR:**
      collapse vs split for `os_theme`. Alternative C (single file,
      runner takes `cmd`). No reason surfaced to flip to B.
- [x] **Resolved-through-implementation decision recorded in AAR:**
      cache invalidation entry point: `M.refresh()`.
- [x] **Resolved-through-implementation decision recorded in AAR:**
      runner contract. Default expectation: runner returns raw
      stdout string (or nil); `detect` parses.

## Proposed tests

A new spec file `tests/colors/os_theme_spec.lua`. The
`pre_case`/`post_case` pattern mirrors
`solarized_subscribe_spec.lua`:

```lua
local _orig_fn_has    = vim.fn.has
local _orig_o_bg      = vim.o.background

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      package.loaded["colors.os_theme"] = nil
      vim.fn.has = function(_) return 0 end
    end,
    post_case = function()
      vim.fn.has = _orig_fn_has
      vim.o.background = _orig_o_bg
      package.loaded["colors.os_theme"] = nil
    end,
  },
})
```

Seven cases:

1. `detect: macOS branch returns "dark" when runner outputs "Dark\n"` —
   stub `vim.fn.has` to return 1 for `"mac"`. Install a fake
   runner returning `"Dark\n"`. Assert `detect() == "dark"` and
   the runner was called exactly once.
2. `detect: macOS branch returns "light" when runner outputs empty` —
   `vim.fn.has("mac") == 1`. Fake runner returns `"\n"`. Assert
   `detect() == "light"`.
3. `detect: macOS branch returns "light" when runner returns nil` —
   `vim.fn.has("mac") == 1`. Fake runner returns `nil` (simulating
   `io.popen` failure). Assert `detect() == "light"`.
4. `detect: Linux branch returns parsed theme from gsettings` —
   `vim.fn.has` returns 0 for `"mac"`, 1 for `"unix"`. Fake runner
   returns `"'Adwaita-dark'\n"` (containing `"dark"` is enough for
   the `:match("Dark")` rule — confirm whether the case-sensitive
   match is intended; if the production code matched only
   capital-D `"Dark"`, the case asserts `"light"` here and a
   second case with `"AdwaitaDark"` asserts `"dark"`). The exact
   parsing rule mirrors `get_os_theme`'s current behavior verbatim.
5. `detect: fallback branch reads vim.o.background` — `vim.fn.has`
   returns 0 for both `"mac"` and `"unix"`. Set
   `vim.o.background = "dark"`. Assert `detect() == "dark"`.
   Repeat with `"light"`.
6. `detect: cache hit on second call (runner invoked once)` —
   any branch (use macOS for concreteness). Counting fake runner.
   Call `detect()` twice. Assert the runner was invoked exactly
   once and both calls returned the same value.
7. `refresh: clears cache so next detect re-runs runner` — install
   counting fake runner. `detect()` (count=1). `refresh()`.
   `detect()` (count=2). Assert second call returned the same
   value (or a new value if the fake's behavior changed between
   calls — the spec demonstrates both).

The `solarized_subscribe_spec.lua` file is touched only to extend
its `pre_case` with one line:
`package.loaded["colors.os_theme"] = nil`. The seven existing
subscribe cases are not otherwise modified; their assertions still
hold because `vim.fn.has` is already stubbed to 0 (routing
`detect` to the fallback branch, where `vim.o.background = "dark"`
yields `"dark"` — the same value `get_os_theme` previously
returned).

## Affected artifacts

- **`lua/colors/os_theme.lua`** (new file) — created with the
  body sketched in Alternative C above.
- **`lua/colors/solarized.lua`**:
  - Local `get_os_theme` function (lines 55–76) deleted.
  - `M.setup` body line 126 changes from
    `local theme = theme_override or get_os_theme()` to
    `local theme = theme_override or require("colors.os_theme").detect()`
    (or equivalent top-of-file local `os_theme` capture).
- **`tests/colors/os_theme_spec.lua`** (new file) — contains the
  seven proposed cases above.
- **`tests/colors/solarized_subscribe_spec.lua`** —
  `pre_case` extended with one line clearing
  `package.loaded["colors.os_theme"]`. No assertion changes.
- **`context/cycles/03-config-deepening/issues/32-theme-subscribe-seam/issue.md`**
  — parent ACs covering the `os_theme` module, the
  `get_os_theme` deletion, and the new `os_theme` spec move from
  `[ ]` to `[x]`. Edits happen as part of this sub-issue's
  closure.

No edits to `lua/config/autocmds.lua` (the `VimEnter` /
`FocusGained` decision is #36's call), to highlight tables in
`solarized.lua`, or to any other file. The `LualineRefresh`
command in `lualine.lua` is not touched.

## Dependencies

- **Sub-issue #34 (closed)** — established the per-test
  fake-the-API pattern (`vim.fn.has` stub specifically) and the
  `package.loaded[...] = nil` reload pattern that
  `os_theme_spec.lua` reuses. Resolved FLAG-32-A so the swap to
  `os_theme.detect()` lands on a stable `setup`/`set_theme`/
  `toggle` path.
- **Sub-issue #33 (closed)** — established the module-local
  registry / no-arg payload contract for subscribe. `os_theme`
  does not interact with subscribe directly; the dependency is
  indirect (subscribe spec is the integration check after the
  swap).
- **Cycle 03 parent #30 (closed)** — proved the ADR-0003
  setter-seam pattern on a shell-bound module (`macos_codesign`).
  The runner-contract decision in this sub-issue (Alternative C,
  `runner(cmd) -> stdout|nil`) deliberately matches
  `macos_codesign.shell.run`'s signature.
- **ADR-0003** — informs the collapse-vs-split decision
  (Question 1). Resolution favors collapse for this module per
  the rationale recorded in the design above.
- **No dependency on later sub-issues under parent #32.** #36
  (closure) decides the `FocusGained`/`VimEnter` autocmd
  disposition based on how `os_theme.detect()` and
  `os_theme.refresh()` shape up under this sub-issue; #36 depends
  on #35, not the other way around.
- **No dependency on parent C.**
