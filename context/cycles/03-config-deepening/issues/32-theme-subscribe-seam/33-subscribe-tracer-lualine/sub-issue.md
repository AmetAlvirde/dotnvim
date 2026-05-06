# Sub-issue #33 — Subscribe tracer + lualine first contact

GitHub issue: #33. First sub-issue under parent #32 (Candidate B —
theme-change subscribe seam) of cycle `03-config-deepening`.

## Description

Tracer slice for parent #32. Establish the smallest end-to-end path
that exercises the new subscribe seam against one real consumer.

Build `colors.solarized.subscribe(fn) -> unsubscribe_fn` and a single
emit point at the end of `solarized.setup()`. Migrate `lualine.lua`
to subscribe (closure re-runs `setup_lualine()` and `redrawstatus`)
and delete the `vim.loop.new_timer()` polling timer.

Leave the four other reaction mechanisms untouched in this sub-issue:

- The `OptionSet`/`background` autocmd in `lualine.lua` stays.
- The `ColorScheme` autocmd in `lualine.lua` stays.
- The three `vim.defer_fn(... LualineRefresh ...)` blocks in
  `solarized.lua` stay.
- The `VimEnter` and `FocusGained` solarized autocmds in
  `autocmds.lua` stay.
- All `print()` debug calls stay.
- `get_os_theme` stays inlined.

This is intentional. The tracer proves the new shape works against
one real consumer with one mechanism retired (the polling timer,
which is the most obviously redundant once subscribe lands).
Subsequent sub-issues consolidate the rest. This mirrors parent #22's
tracer approach: `ObsCLITasks` migrated alone, the other 17 commands
untouched until the test pattern was proven.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `vim.api.nvim_set_hl` (called by `solarized.setup()`) | True external (Neovim API) | Inject a no-op fake via per-test `vim.api.nvim_set_hl` swap in `pre_case`; restore in `post_case`. Same pattern parent #22 used for `vim.api.nvim_create_user_command`. |
| `vim.cmd` / `vim.defer_fn` (called downstream of `setup()`) | True external (Neovim API) | Inject no-op fakes via `pre_case`; restore via `mini.test.finally` or `post_case`. |
| `vim.fn.has` / `io.popen` (inside `get_os_theme`, still inlined this sub-issue) | True external | Stub `vim.fn.has` to return 0 in tests so the shell-out branch is skipped. Setting `vim.o.background` directly drives the fallback branch. |
| `colors.solarized` module itself | In-process | Test directly through the new `subscribe`/emit interface. |
| `lualine` plugin | Local-substitutable in production; not exercised in tests | Lualine's `setup_lualine` closure is wired to subscribe; the test does not load lualine. The subscribe contract test asserts callback delivery, not statusline rendering. |

No new ports introduced — the subscribe registry is single-consumer
in production (lualine), single-consumer in test (the fake), and
internal to `colors.solarized`. Per cycle PRD open question #3, no
generalization to a configuration-wide event bus.

## Interface design

Two design alternatives compared. Final choice resolved in this
sub-issue's AAR per the parent issue's "resolved through
implementation" notes.

### Alternative A — module-local registry inside `solarized.lua`

```lua
-- in lua/colors/solarized.lua

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
  for _, sub in ipairs(subscribers) do pcall(sub) end
end

-- ... existing setup() body ...
function M.setup()
  -- ... unchanged work ...
  vim.g.colors_name = "solarized"
  emit()  -- single emit, replaces the deferred LualineRefresh blocks
          -- (those blocks are deleted in a subsequent sub-issue,
          -- not this one)
end
```

**Pros:** Lowest indirection. Subscribe state lives next to the
emitter. Single-consumer scope makes a separate module premature.
Mirrors parent #22's resolution (registrar lives in
`lua/config/commands_registrar.lua` because it's single-consumer
within `lua/config/`).

**Cons:** If a second consumer surfaces (treesitter overrides, sign
column), promotion to `lua/colors/subscribe.lua` is one edit. No
real cost.

### Alternative B — sibling module `lua/colors/subscribe.lua`

```lua
-- in lua/colors/subscribe.lua
local M = {}
local subscribers = {}
function M.on(fn)  ... end
function M.emit()  ... end
return M

-- in lua/colors/solarized.lua
local subscribe = require("colors.subscribe")
M.subscribe = subscribe.on
-- at end of setup():
subscribe.emit()
```

**Pros:** The seam is unambiguously a separate module; future
generalization is structurally invited.

**Cons:** Premature generalization per cycle PRD open question #3.
Adds a require cycle if the subscribe module ever wants to know
the current theme. Two-file shape buys nothing for one consumer.

### Alternative C — `fn(payload)` payload shape question (orthogonal to A/B)

Sub-question: what does `fn` receive when called?

- **C1 — `fn()` (no args):** Subscriber pulls `vim.o.background` /
  current colors itself. Simplest. Matches lualine's existing
  `create_solarized_theme()` which already reads `vim.o.background`.
- **C2 — `fn(theme)` where `theme = "dark"|"light"`:** Event carries
  the new state. More explicit; subscriber doesn't need to know
  where to look.
- **C3 — `fn(payload)` where `payload = { background, colors, name }`:**
  Maximum information. Premature; no consumer needs `name` or
  pre-resolved colors.

### Chosen (proposed; final in AAR)

**A + C1.** Module-local registry; `fn()` no-arg payload.

**Reason for A:** Single consumer, mirrors parent #22's
single-consumer-keeps-it-local resolution, lowest blast radius if
the design needs to change.

**Reason for C1:** Lualine already reads `vim.o.background` to
build its theme. Passing the value would be a duplicate piece of
information at the seam. If C2 is wanted later, adding an arg is
backwards-compatible.

**Rejected B:** premature generalization per cycle PRD open
question #3.

**Rejected C2/C3:** speculative payloads with no consumer demand.

The AAR records the final form of this sub-issue's decision; if
implementation surfaces a reason to flip A→B or C1→C2, the AAR
records that reason and the parent's "resolved through
implementation" AC checks accordingly.

### Public interface (post-sub-issue)

```lua
-- colors.solarized
M.subscribe(fn) -> unsubscribe_fn   -- new public surface
M.setup()                            -- unchanged signature; emits once at end
M.set_theme(theme)                   -- unchanged signature; reaches emit via setup()
M.toggle()                           -- unchanged signature; reaches emit via setup()
M.colors / M.dark_colors / M.light_colors  -- unchanged
```

```lua
-- plugins.lualine config block
local solarized = require("colors.solarized")
local function setup_lualine() ... end  -- unchanged
setup_lualine()
solarized.subscribe(function()
  vim.defer_fn(function()
    setup_lualine()
    vim.cmd("redrawstatus")
  end, 100)
end)
-- vim.loop.new_timer block: DELETED
-- OptionSet autocmd: still here (next sub-issue removes)
-- ColorScheme autocmd: still here (next sub-issue removes)
-- LualineRefresh user command: still here (preserved per parent issue)
```

The `vim.defer_fn(..., 100)` inside the subscriber matches the
existing 100ms delay the OptionSet autocmd uses, preserving
observable timing during the tracer. A subsequent sub-issue may
revisit whether the defer is still needed once the autocmd is
deleted.

## Acceptance criteria

- [ ] `colors.solarized.subscribe(fn)` returns a callable
      `unsubscribe_fn`. Subscribers registered before
      `setup()` is called receive the emit at the end of `setup()`.
- [ ] Calling `unsubscribe_fn()` removes the subscriber. Subsequent
      `setup()` invocations do not call the removed subscriber.
- [ ] Calling `unsubscribe_fn()` a second time is a no-op (no
      error, no double-removal).
- [ ] `solarized.setup()` emits exactly once per call. Verified
      with a counting subscriber across `set_theme("dark")` and
      `set_theme("light")` calls — count increments by 1 each.
- [ ] `lua/plugins/lualine.lua` calls `solarized.subscribe(fn)`
      exactly once in its `config` block.
- [ ] The `vim.loop.new_timer()` block in `lua/plugins/lualine.lua`
      (currently lines ~167–180) is deleted. Verified by
      `grep -n 'vim\.loop\.new_timer' lua/plugins/lualine.lua`
      returning zero matches.
- [ ] The two lualine reaction autocmds (`OptionSet`/`background`
      and `ColorScheme`), the three `vim.defer_fn(...
      LualineRefresh ...)` blocks in `solarized.lua`, the `print()`
      statements, and the inlined `get_os_theme` are **explicitly
      preserved unchanged** in this sub-issue. Verified by
      `git diff` on lines outside the subscribe-introduction and
      polling-timer-deletion regions being empty in those scopes.
- [ ] At least one passing unit test exists at
      `tests/colors/solarized_subscribe_spec.lua` exercised by
      `./tests/run`. The test fakes `vim.api.nvim_set_hl`,
      `vim.cmd`, and `vim.defer_fn` via the per-case swap pattern
      from parent #22 and exercises: register → `set_theme(...)`
      → assert callback called once; unsubscribe → `set_theme(...)`
      → assert callback not called; double-unsubscribe → no error.
- [ ] `./tests/run` exits 0 on the whole suite — including all
      cycle 01, cycle 02, and cycle 03 (parents #22, #30) specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent —
      the suite passes with `obsidian`, `codesign`, and `defaults`
      absent from `$PATH`). The new spec must not require `defaults`
      to exist; stubbing `vim.fn.has` to 0 routes around the
      `get_os_theme` shell-out for the duration of the test.
- [ ] No reaching into local functions or monkey-patching
      internals beyond the sanctioned per-test
      `vim.api.nvim_set_hl` / `vim.cmd` / `vim.defer_fn` /
      `vim.fn.has` swaps that the subscribe contract explicitly
      invites.
- [ ] **Resolved-through-implementation decisions recorded in
      AAR:** subscribe registry location (Alt. A vs Alt. B) and
      payload shape (C1 vs C2 vs C3). Default proposal: A + C1.

## Proposed tests

Single new spec file: `tests/colors/solarized_subscribe_spec.lua`.

Test cases:

1. `subscribe registers a function and emit calls it` — register a
   recording fake, call `set_theme("dark")`, assert the fake was
   called exactly once.
2. `setup emits exactly once per invocation` — register a counting
   fake, call `set_theme("dark")` then `set_theme("light")`, assert
   the count is 2.
3. `unsubscribe removes the subscriber` — register, call set_theme
   (count becomes 1), call `unsubscribe_fn()`, call set_theme
   again, assert the count is still 1.
4. `unsubscribe is idempotent` — call `unsubscribe_fn()` twice in a
   row, assert no error and no spurious side effect.
5. `multiple subscribers all receive the emit` — register two
   recording fakes, call set_theme, assert both received the call.
6. `one subscriber raising an error does not block another` — the
   `pcall(sub)` wrapping in `emit()` ensures one subscriber's
   error doesn't prevent the next from running. Register a
   throwing fake and a recording fake; assert recording fake still
   called.

`pre_case` swaps:

- `vim.api.nvim_set_hl` → no-op fake (counts ~150 calls per
  `setup()`; we don't care about call shape, only that the function
  doesn't fail in headless context).
- `vim.cmd` → no-op fake (handles `redraw!` invocation and other
  commands inside `set_theme`/`toggle`).
- `vim.defer_fn` → invokes the callback synchronously (so the
  three currently-still-present LualineRefresh blocks don't
  schedule timer work that outlives the test case). Note: this is
  the simplest-possible fake; it discards the delay parameter.
- `vim.fn.has` → returns 0 for both `"mac"` and `"unix"` so
  `get_os_theme` falls back to `vim.o.background`-derived value
  without shelling out.

`post_case` (or `mini.test.finally` per the cycle 02 pattern):
restore each swapped value to the original. The test must not leak
fakes into the next test case.

## Affected artifacts

- **`lua/colors/solarized.lua`** — add `subscribers` table, add
  `subscribe(fn) -> unsubscribe_fn`, add `emit()` helper, call
  `emit()` once at end of `setup()`. No deletions in this
  sub-issue beyond the (zero) lines that already exist for these
  symbols.
- **`lua/plugins/lualine.lua`** — add the
  `solarized.subscribe(fn)` call in the `config` block, delete
  the `vim.loop.new_timer()` block (lines ~167–180 inclusive of
  the surrounding comment "-- Create a timer to periodically check
  for background changes").
- **`tests/colors/solarized_subscribe_spec.lua`** — new file;
  `tests/colors/` directory does not yet exist and is created in
  this sub-issue.
- **`tests/init.lua`** — confirm the new test directory is picked
  up by the existing `tests/run` mechanism (likely no edit needed
  if the runner globs `tests/**/*_spec.lua`; verify during
  implementation).

## Dependencies

- **Cycle 03 parent #22 (A) closure** — established the
  fake-the-API per-case swap pattern that this sub-issue's spec
  reuses. Closed.
- **Cycle 03 parent #30 (D) closure** — proved the discipline of
  not reaching into module locals beyond sanctioned setter seams.
  Closed.
- **No dependency on later sub-issues under parent #32.** This
  sub-issue is the tracer; #34/#35/#36 build on its proof.
- **No dependency on parent C** (cycle 03's last parent).
