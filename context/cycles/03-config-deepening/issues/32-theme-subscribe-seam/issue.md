# Parent Issue — Theme-change subscribe seam (Candidate B)

GitHub issue: #32. Third parent of cycle `03-config-deepening`,
landing third per the cycle PRD's resolved sequencing
(A → D → B → C). Translates `sub-prd.md` into a trackable technical
unit. The two artifacts are complementary — `sub-prd.md` records
product-level intent (user stories, scope, dependencies); this file
records the technical contract (acceptance criteria, implementation
approach, flags).

## Acceptance criteria

- [ ] `lua/colors/solarized.lua` exposes
      `M.subscribe(fn) -> unsubscribe_fn`, publicly `require`-able.
      Calling `subscribe` returns a callable that removes the
      registered subscriber from the registry. Calling the returned
      callable twice is a no-op (idempotent).
- [ ] `solarized.setup()` emits exactly once at the end of its body
      to every registered subscriber. `set_theme()` and `toggle()`
      reach the emit through their existing call to `setup()`; they
      do not emit a second time. Verified by a unit test that
      registers a counting subscriber and asserts call count = 1
      per `set_theme(...)` invocation.
- [ ] `lua/plugins/lualine.lua` calls `solarized.subscribe(fn)`
      exactly once in its `config` block, with `fn` being a closure
      that re-runs `setup_lualine()` and `redrawstatus`. The
      `vim.loop.new_timer()` polling timer is deleted. Verified by
      `grep -n 'vim\.loop\.new_timer' lua/plugins/lualine.lua`
      returning zero matches.
- [ ] The `OptionSet`/`background` autocmd and the `ColorScheme`
      autocmd in `lua/plugins/lualine.lua` are deleted. All of
      lualine's theme-reaction goes through subscribe. Verified by
      `grep -n "nvim_create_autocmd" lua/plugins/lualine.lua`
      returning zero matches.
- [ ] The three `vim.defer_fn(... LualineRefresh ...)` blocks in
      `lua/colors/solarized.lua` (currently at lines ~496–500,
      ~519–526, ~539–544) are deleted. Subscribe replaces them.
      Verified by `grep -n 'LualineRefresh' lua/colors/solarized.lua`
      returning zero matches.
- [ ] All `print()` statements in the theme-change code paths are
      removed — both the live debug calls in `solarized.lua` (lines
      ~511, ~520, ~524) and the live or commented `print(...)` lines
      in `lualine.lua`. Verified by
      `grep -rn '^\s*print(' lua/colors/ lua/plugins/lualine.lua`
      returning zero matches and
      `grep -rn '^\s*-- print(' lua/colors/ lua/plugins/lualine.lua`
      returning zero matches in the theme paths.
- [ ] `lua/colors/os_theme.lua` exists, exposing
      `M.detect() -> "dark" | "light"`. The module follows
      ADR-0003's runner-seam shape: a default runner that shells out
      via `io.popen`, plus `M.set_runner(fn)` and `M.reset_runner()`
      setters. The `defaults read AppleInterfaceStyle` shell-out
      fires only on cache miss or after `M.refresh()` is called —
      not on every invocation of `M.detect()`. Whether the module
      collapses runner+command into one file or splits per ADR-0003's
      four-layer pattern (`command.lua`, `shell.lua`) is resolved
      through implementation in this parent's first sub-issue and
      recorded in its AAR.
- [ ] `solarized.setup()` calls `require("colors.os_theme").detect()`
      instead of the currently-inlined `get_os_theme` local function.
      The local `get_os_theme` is removed from `solarized.lua`.
- [ ] The `VimEnter` and `FocusGained` solarized autocmds in
      `lua/config/autocmds.lua` are addressed: either retained with
      a one-line `desc` recording the reason (e.g. "trigger
      `os_theme.refresh()` on focus to detect system theme flips")
      or collapsed if subscribe + `os_theme` cache cover the
      observable behavior. Decision recorded in this parent's
      closing AAR. No other autocmd handler in `autocmds.lua` is
      touched.
- [ ] At least one passing unit test exists under `tests/colors/`
      exercising the subscribe contract: register a fake subscriber,
      call `solarized.set_theme("dark")` (with `vim.api.nvim_set_hl`,
      `vim.cmd`, `vim.defer_fn` stubbed via the established
      fake-the-API pattern), assert the fake was called once with
      the expected payload. The test also covers
      `unsubscribe_fn()` removing the subscriber and idempotent
      double-unsubscribe.
- [ ] At least one passing unit test exists under `tests/colors/`
      exercising `os_theme.detect()`: a fake runner is installed via
      `set_runner`, a first call to `detect()` invokes the runner
      and returns the parsed theme, a second call returns the cached
      value without invoking the runner, and `M.refresh()` (or
      equivalent invalidation entry point) clears the cache.
- [ ] `./tests/run` exits 0 on the whole suite — including all
      cycle 01, cycle 02, and cycle 03 (parents #22, #30) specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `obsidian`, `codesign`, and `defaults`
      absent from `$PATH`). The `os_theme` runner-seam ensures the
      test never invokes the real `defaults` binary.
- [ ] No reaching into local functions or monkey-patching internals
      in any new spec. Carry-forward acceptance criterion from
      cycles 01–02 and parents #22, #30, still binding. The two
      sanctioned substitution points are `os_theme.set_runner` and
      the per-test fakes for `vim.api.nvim_set_hl`, `vim.cmd`,
      `vim.defer_fn` (the pattern parents #22 and #30 established).
- [ ] **Resolved-through-implementation decision recorded:**
      subscribe registry location — module-local table inside
      `solarized.lua`, or extracted to `lua/colors/subscribe.lua`.
      Decided in first sub-issue (#33) and recorded in its AAR.
      Default expectation: module-local, per cycle PRD open
      question #3's caution against premature generalization.
- [ ] **Resolved-through-implementation decision recorded:** subscribe
      payload shape — `fn()` (no-arg, subscriber pulls
      `vim.o.background`) vs `fn(theme)` vs `fn(payload_table)`.
      Decided in first sub-issue (#33).
- [ ] **Resolved-through-implementation decision recorded:** subscribe
      generalization (cycle PRD open question #3). Default expectation
      after this parent closes: scope strictly to
      `colors.solarized.subscribe`; no second consumer surfaced in
      cycle 03. Recorded in this parent's closing AAR.
- [ ] **Resolved-through-implementation decision recorded:** ADR-0004
      candidate for the subscribe-registry pattern (cycle PRD open
      question #4). Default expectation: defer to cycle 03 PRD close,
      where the family of seams (registrar from A, subscribe from B)
      may share an ADR. Recorded in this parent's closing AAR.

## Implementation approach

### Subscribe interface (sketch — final shape decided in first sub-issue)

```lua
-- in lua/colors/solarized.lua (or a sibling module — resolved in #33)

local subscribers = {}

function M.subscribe(fn)
  table.insert(subscribers, fn)
  local removed = false
  return function()
    if removed then return end
    removed = true
    for i, sub in ipairs(subscribers) do
      if sub == fn then
        table.remove(subscribers, i)
        return
      end
    end
  end
end

local function emit()
  -- payload shape resolved in #33; default sketch passes nothing
  for _, sub in ipairs(subscribers) do
    pcall(sub)
  end
end
```

`emit()` is called exactly once at the end of `setup()`. Because
`set_theme()` and `toggle()` already delegate to `setup()`, they
inherit the single emit without any explicit additional call.

### `os_theme` module (Candidate E, sketch)

```lua
-- in lua/colors/os_theme.lua

local M = {}

local default_runner = function()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  return result
end

local runner = default_runner
local cached -- "dark" | "light" | nil (nil = miss)

function M.set_runner(fn) runner = fn end
function M.reset_runner() runner = default_runner end
function M.refresh() cached = nil end

function M.detect()
  if cached ~= nil then return cached end
  if vim.fn.has("mac") == 1 then
    local out = runner()
    cached = (out and out:match("Dark")) and "dark" or "light"
  elseif vim.fn.has("unix") == 1 then
    -- gsettings branch — same shape, deferred unless cycle scope demands
    cached = vim.o.background == "dark" and "dark" or "light"
  else
    cached = vim.o.background == "dark" and "dark" or "light"
  end
  return cached
end

return M
```

ADR-0003's full four-layer split (`command.lua`, `shell.lua`,
`parsers.lua`, `presenter.lua`) likely collapses for `os_theme` —
the command is one literal string, the parser is one `:match`,
there is no presenter. Whether to keep it as a single
`os_theme.lua` file (collapsed) or split it into
`os_theme/init.lua` + `os_theme/shell.lua` (ADR-0003-strict) is a
first-sub-issue decision, recorded in its AAR. Parent #30 set the
precedent that command-building can collapse into the same file
when trivial; B inherits that latitude.

### Reaction-mechanism collapse

| # | Mechanism | Currently in | After B |
| - | --- | --- | --- |
| 1 | `vim.loop.new_timer()` polling | `lualine.lua` | **deleted** |
| 2 | `OptionSet`/`background` autocmd | `lualine.lua` | **deleted** (subscribe replaces) |
| 3 | `ColorScheme` autocmd | `lualine.lua` | **deleted** (subscribe replaces) |
| 4 | Three `vim.defer_fn(... LualineRefresh ...)` blocks | `solarized.lua` | **deleted** (subscribe replaces) |
| 5 | `FocusGained` autocmd re-running `setup()` | `autocmds.lua` | **retained-with-reason** OR collapsed (decided in #34 / closure) |
| 6 | `VimEnter` autocmd calling `setup()` | `autocmds.lua` | **retained** (startup trigger; no consumer-side concern) |

Mechanism 5 is the subtle one: it exists to detect a system theme
flip when the user returns to nvim. After E lands with cached
`os_theme`, `FocusGained` is the only path that *invalidates* the
cache (or just calls `os_theme.refresh()` then `setup()` if state
changed). The retain-or-collapse decision waits on E's behavior.

### Test pattern (the seam this parent issue establishes for C)

The subscribe contract is testable without a live Neovim editing
session, but `solarized.setup()` has heavy `vim.api.nvim_set_hl`
side effects that the test must tolerate. Approach:

1. In `pre_case`, swap `vim.api.nvim_set_hl`, `vim.cmd`, and
   `vim.defer_fn` for no-op fakes that record nothing (the test
   doesn't care about highlight state — only about subscribe
   delivery).
2. Register a fake subscriber via `solarized.subscribe`.
3. Call `solarized.set_theme("dark")`.
4. Assert the fake was called once with the expected payload.
5. Call the returned `unsubscribe_fn()`; call `set_theme("light")`;
   assert no further callback.
6. Call `unsubscribe_fn()` a second time; assert no error
   (idempotent).
7. In `post_case`, restore the originals via `mini.test.finally`.

The `os_theme` test uses the same pattern parent #30 established:
a recording fake injected via `set_runner`, a stub for `vim.fn.has`,
assertions on the parsed return and on cache behavior across two
`detect()` calls.

No `mini.test.new_child_neovim`. No reaching into module-locals.
The subscribe and runner setters are the seams; everything tests
through them.

### Sequencing

Per the cycle 01 process spec — Stage 1 tracer → Stages 2–3
incremental TDD → Stage 4 deepen — this parent issue maps to:

- **First sub-issue (#33):** tracer slice. Build
  `solarized.subscribe` + single emit in `setup()`. Migrate lualine
  to subscribe and delete the `vim.loop.new_timer()` polling timer.
  Leave the four other reaction mechanisms in place — the lualine
  autocmds, the three deferred LualineRefresh blocks in
  solarized.lua, the prints, and `get_os_theme`. Add the first
  subscribe spec exercising registration, single emit, and
  unsubscribe. Resolve the registry-location and payload-shape
  decisions in this sub-issue's AAR.

- **Second sub-issue (#34, name TBD):** lualine consolidation +
  print removal. Delete the two lualine reaction autocmds
  (`OptionSet`/`background`, `ColorScheme`). Delete the three
  `vim.defer_fn(... LualineRefresh ...)` blocks in
  `solarized.lua`. Remove all `print()` statements in the
  theme-change paths in both files. The subscribe seam is now
  lualine's only reaction channel.

- **Third sub-issue (#35, name TBD):** `os_theme` extraction
  (Candidate E). Build `lua/colors/os_theme.lua` with
  `detect()` + cache + `set_runner`/`reset_runner`/`refresh` per
  the ADR-0003 sketch. Update `solarized.setup()` to call
  `os_theme.detect()`. Add the `os_theme` spec. Decide the
  ADR-0003 split-vs-collapse question for `os_theme` and record
  in this sub-issue's AAR.

- **Closing sub-issue (#36, name TBD):** decide the
  `FocusGained`/`VimEnter` autocmd disposition (retain-with-reason
  vs collapse) given how E shaped the cache-invalidation flow.
  Record the open-question resolutions: subscribe-registry
  generalization (cycle PRD open Q #3) and ADR-0004 candidate
  (cycle PRD open Q #4). Verify all parent ACs are checked. Sibling
  `aar.md`. The next GitHub issue number belongs to the next parent
  issue (Candidate C) in the cycle.

The sub-issue groupings are deliberately a rough plan — the final
sequencing of #34/#35 (or whether one collapses into the other) is
informed by the AARs as they land. Sub-issue numbering follows
ADR-0002 — sequential GitHub issue numbers, not cycle-local
numbers.

### Constraints binding the implementation

1. The 18 user commands and the three `:Solarized*` commands keep
   their names and argument shapes. No command is added, renamed,
   or removed in this parent issue.
2. No edits to `lua/utils/obsidian_cli/`, `lua/utils/wordcount.lua`,
   `lua/utils/macos_codesign/`, or any autocmd in
   `lua/config/autocmds.lua` other than the two solarized
   handlers (`VimEnter`, `FocusGained`).
3. No edits to highlight tables in `lua/colors/solarized.lua`.
   Highlight decomposition is Candidate C, not B.
4. Tests exercise public interfaces only. No reaching into locals,
   no monkey-patching internals beyond the per-test
   `vim.api.nvim_set_hl` / `vim.cmd` / `vim.defer_fn` swaps that
   the subscribe contract explicitly invites and the
   `set_runner`/`reset_runner` seam on `os_theme`.
5. The test suite runs to green with `defaults`, `obsidian`, and
   `codesign` absent from `$PATH`. The `os_theme` runner seam
   ensures tests never invoke the real `defaults` binary.
6. No new plugin dependencies. `mini.test` from cycle 01 remains
   the only test tooling.
7. The plugin-internal `LualineRefresh` user command in
   `lualine.lua` is preserved (out of registrar contract per
   parent #22's AAR; useful as a manual-fallback handle for the
   maintainer).

## Dependencies

- **Cycle 01 closure** — `mini.test` harness in place at
  `./tests/run`, `tests/init.lua` bootstrap with the `os.exit(0)`
  short-circuit preserved. Already closed.
- **Cycle 03 parent #22 (A) closure** — established the
  fake-the-API test pattern (swap a `vim.api.*` call for a fake
  in `pre_case`, restore in `post_case`). B reuses it for the
  subscribe-contract test. Already closed.
- **Cycle 03 parent #30 (D) closure** — proved the ADR-0003
  setter-seam pattern works on a new shell-bound module type.
  B's `os_theme` extraction follows the same shape. Already
  closed.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `32-theme-subscribe-seam` tracks
  GitHub issue #32; sub-issues take sequential GitHub numbers.
- **ADR-0003** — runner-seam shape for shell-bound utilities.
  Binding for the `os_theme` extraction; collapse-vs-split decided
  in the relevant sub-issue.
- **No dependency on parent C.** C is the last parent in the
  resolved sequencing and depends forward on B's collapse to make
  the highlight-decomposition reshape simpler.

## Flags

*None yet. Sub-issue AARs surface flags as they appear.*
