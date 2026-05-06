# Sub-issue #34 — Lualine consolidation + print removal

GitHub issue: #34. Second sub-issue under parent #32 (Candidate B —
theme-change subscribe seam) of cycle `03-config-deepening`.

## Description

Consolidation slice for parent #32. With the subscribe seam in place
and proven against lualine (#33), retire the four theme-reaction
mechanisms that the seam now obsoletes and the live/commented
`print()` debugging that survived the tracer pass. Resolve
FLAG-32-A — the colorscheme-reapply double-emit observed during
#33's deepening — so that `set_theme()` produces exactly one emit
per invocation regardless of background-direction.

Concretely, after this sub-issue:

- `lua/plugins/lualine.lua` reads top-to-bottom as a declarative
  spine: `setup_lualine()` initial call, one `solarized.subscribe(fn)`,
  the lualine config closure, and the preserved `LualineRefresh` user
  command. No polling timer (already gone in #33), no `OptionSet`
  autocmd, no `ColorScheme` autocmd.
- `lua/colors/solarized.lua`'s three `vim.defer_fn(... LualineRefresh ...)`
  blocks (one in `M.setup()` end, one in `M.toggle()`, one in
  `M.set_theme()`) are deleted. Subscribe is the only reaction
  channel.
- All live `print()` calls (`solarized.lua` toggle path; `lualine.lua`
  `ColorScheme` autocmd) and all commented `-- print(...)` lines in
  the theme paths of both files are removed.
- `set_theme()` and `toggle()` emit exactly once per invocation,
  even when the background direction flips. FLAG-32-A is resolved.

The `LualineRefresh` user command in `lualine.lua` is preserved
verbatim per parent #22's AAR (plugin-internal manual-fallback
handle), with its trailing commented `print` line removed.

The `VimEnter` and `FocusGained` autocmds in `lua/config/autocmds.lua`,
the inlined `get_os_theme` in `solarized.lua`, and all highlight
tables stay untouched. Those belong to #35 and #36 (and to parent C
respectively).

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `colors.solarized.subscribe` / emit | In-process | Already tested via `tests/colors/solarized_subscribe_spec.lua`. Extend with one new case asserting single emit on `set_theme` background-flip. |
| `vim.api.nvim_set_hl` | True external (Neovim API) | Per-test no-op fake via `pre_case`/`post_case`, established in #33. |
| `vim.cmd` | True external (Neovim API) | Per-test no-op fake. The new flip-test must allow `vim.cmd("redraw!")` (or whichever path remains in `set_theme`/`toggle`) without exploding. |
| `vim.defer_fn` | True external (Neovim API) | Per-test fake invokes the callback synchronously; same as #33. With the three defer blocks deleted, `setup()`/`toggle()`/`set_theme()` no longer call `vim.defer_fn` at all — only lualine's subscriber closure does, and that closure is not exercised in the spec. |
| `vim.fn.has` | True external (Neovim API) | Stub to return 0 for `"mac"` and `"unix"` so `get_os_theme` falls back to `vim.o.background`-derived value. |
| Neovim's colorscheme re-apply (executes `colors/solarized.lua` when `vim.o.background` flips while `vim.g.colors_name = "solarized"`) | Engine behavior, not a code path we own | The re-apply trigger fires on background change. The chosen FLAG-32-A resolution must avoid producing a duplicate emit through this path. The spec verifies single-emit by asserting count = 1 after a `set_theme` call that flips background; the test sets `vim.g.colors_name = "solarized"` in `pre_case` so the re-apply path is realistic. |
| `lualine` plugin | Local-substitutable in production; not exercised in tests | Lualine's subscriber closure is unchanged in shape (still wraps `setup_lualine()` + `redrawstatus` in a `vim.defer_fn(..., 100)`). Not loaded in tests. |

No new ports. No new external dependencies. The four mechanisms
being deleted are pure removals; the FLAG-32-A fix is a small
internal reshape to `M.setup` / `M.set_theme` / `M.toggle`.

## Interface design

The public surface does not grow. Three internal questions:

1. How to suppress the colorscheme-reapply double-emit when
   `set_theme` / `toggle` flip `vim.o.background`.
2. Whether `M.setup` accepts a theme override or stays no-arg.
3. Where the residual `vim.cmd("redraw!")` in `toggle()` and
   `set_theme()` lives after the defer blocks are deleted.

### Question 1 — re-apply suppression (the FLAG-32-A fix)

When `vim.o.background` is assigned a new value while
`vim.g.colors_name == "solarized"`, Neovim re-executes
`colors/solarized.lua` (the runtimepath entry-point), which calls
`solarized.setup()`, which emits. Then the explicit `M.setup()`
call inside `set_theme`/`toggle` emits again. Two emits per
logical theme-change.

Three alternatives compared.

#### Alternative A — clear `vim.g.colors_name` before flipping background

```lua
function M.set_theme(theme)
  if theme == "dark" or theme == "light" then
    vim.g.colors_name = nil  -- suppress the reapply autocmd for this transition
    M.setup(theme)            -- setup re-asserts colors_name = "solarized" at its end
  end
end

function M.toggle()
  vim.g.colors_name = nil
  M.setup(vim.o.background == "dark" and "light" or "dark")
end
```

`M.setup` learns to take an optional `theme_override` so that the
caller's intent (the user's `set_theme("dark")`) wins over
`get_os_theme()`'s OS reading. Without that, `set_theme("dark")`
on macOS in light mode silently reverts to "light" because
`get_os_theme()` reads the OS state — a latent bug surfaced by
this analysis but not introduced by it.

**Pros:** Direct, honest, minimal diff. The mechanism we're
suppressing is named explicitly. The override fixes the latent
"user choice loses to OS state" bug as a side benefit. No new
state. The single emit comes from `setup`'s own end-of-body
`emit()`.

**Cons:** Briefly nils `vim.g.colors_name`. If anything else
reads `vim.g.colors_name` during the gap (within a single
synchronous call chain, nothing should), it observes `nil`.
Acceptable: the gap is one `M.setup` call deep and synchronous.

#### Alternative B — re-entry guard (mutex flag)

```lua
local applying = false

function M.setup(theme_override)
  if applying then return end
  applying = true
  -- ... existing body ...
  applying = false
  emit()
end
```

The reapply path's nested `M.setup()` call is short-circuited;
only the outermost call does work and emits.

**Pros:** No interaction with `vim.g.colors_name` semantics.

**Cons:** The reapply still happens (Neovim still runs
`colors/solarized.lua`), and the no-op'd inner setup means we
*skip* the highlight reapplication that the engine wanted us to
do. In practice the outer setup will re-apply the highlights,
but the dependency on call ordering is subtle and the guard hides
the suppression rather than naming it. Adds module-local mutable
state that future readers must reason about.

#### Alternative C — leave the double-emit; dedupe at subscriber

```lua
-- in lualine config
local last_emit = 0
solarized.subscribe(function()
  local now = vim.loop.now()
  if now - last_emit < 50 then return end
  last_emit = now
  vim.defer_fn(function() ... end, 100)
end)
```

**Pros:** No solarized.lua change.

**Cons:** Time-based dedupe is fragile. Pushes the seam's contract
violation onto every consumer. Contradicts parent #32's "emit
exactly once at the end of `setup()`" AC in spirit. Rejected.

#### Chosen (proposed; final in AAR)

**Alternative A.** Clear `vim.g.colors_name` before flipping
background; teach `M.setup` to accept an optional theme override.

**Reason for A:** The reapply trigger is named (`vim.g.colors_name`
gating it), the suppression is named (clearing it), and the
override fixes a latent correctness bug. Diff is small.

**Rejected B:** Hides the suppression in module-local state and
skips work the engine asked for. The complexity-to-benefit ratio
is worse.

**Rejected C:** Pushes the contract violation to every future
subscriber. Contradicts the parent AC.

If implementation surfaces a reason to flip A→B (e.g. some
plugin's `OptionSet`-handler reads `vim.g.colors_name == "solarized"`
to gate behavior and breaks during the gap), the AAR records that
reason and the resolution.

### Question 2 — `M.setup` signature

```lua
function M.setup(theme_override)
  local theme = theme_override or get_os_theme()
  -- ... rest unchanged ...
end
```

Backwards-compatible: existing callers (`colors/solarized.lua`
entry-point, `VimEnter` autocmd, `FocusGained` autocmd) call
`M.setup()` with no args and continue to use `get_os_theme()`.
The override exists so `set_theme(theme)` / `toggle()` can pass
the user's choice through without touching `vim.o.background`
twice.

### Question 3 — residual `vim.cmd("redraw!")`

`M.toggle()` currently calls `vim.cmd("redraw!")` after `M.setup()`
(line ~540). `M.set_theme()` does the same (line ~560). These
calls force Neovim to repaint immediately rather than at the next
event-loop tick. They are not part of the LualineRefresh deferred
blocks; they exist to make the *colorscheme switch itself* feel
instantaneous to the user.

After the LualineRefresh defer blocks are deleted, the
`vim.cmd("redraw!")` calls remain. They sit between `M.setup()`
and the function's return. Subscribe has already fired at that
point (inside `M.setup`'s end), so lualine's defer-100 will
queue a `redrawstatus` ~100ms later. The synchronous `redraw!`
is for everything else (treesitter, signs, gutter) and stays.

### Public interface (post-sub-issue)

```lua
-- colors.solarized
M.setup(theme_override)              -- new optional arg; no-arg call unchanged
M.set_theme(theme)                   -- unchanged signature; one emit per call
M.toggle()                           -- unchanged signature; one emit per call
M.subscribe(fn) -> unsubscribe_fn    -- unchanged from #33
M.colors / M.dark_colors / M.light_colors  -- unchanged
```

```lua
-- plugins.lualine config block (post-sub-issue shape)
local solarized = require("colors.solarized")
local function create_solarized_theme() ... end  -- unchanged
local function setup_lualine() ... end           -- unchanged
setup_lualine()
solarized.subscribe(function()
  vim.defer_fn(function()
    setup_lualine()
    vim.cmd("redrawstatus")
  end, 100)
end)
vim.api.nvim_create_user_command('LualineRefresh', function()
  setup_lualine()
  vim.cmd("redrawstatus")
end, { desc = 'Manually refresh lualine theme' })
-- OptionSet autocmd: DELETED
-- ColorScheme autocmd: DELETED
-- Commented `-- print(...)` lines: DELETED
```

## Acceptance criteria

- [x] `lua/plugins/lualine.lua` no longer contains an `OptionSet`
      autocmd. Verified by
      `grep -n "OptionSet" lua/plugins/lualine.lua` returning zero
      matches.
- [x] `lua/plugins/lualine.lua` no longer contains a `ColorScheme`
      autocmd. Verified by
      `grep -n "ColorScheme" lua/plugins/lualine.lua` returning zero
      matches.
- [x] `lua/plugins/lualine.lua` contains zero `nvim_create_autocmd`
      calls. Verified by
      `grep -n "nvim_create_autocmd" lua/plugins/lualine.lua`
      returning zero matches. (Carry-forward from parent #32 AC.)
- [x] `lua/colors/solarized.lua` contains zero
      `vim.defer_fn(... LualineRefresh ...)` blocks. Verified by
      `grep -n "LualineRefresh" lua/colors/solarized.lua` returning
      zero matches.
- [x] All live and commented `print(...)` lines in the theme paths
      of both files are removed. Verified by
      `grep -n "print(" lua/colors/solarized.lua lua/plugins/lualine.lua`
      returning zero matches.
- [x] The `LualineRefresh` user command in `lua/plugins/lualine.lua`
      is preserved (its body and `desc`). Verified by reading the
      file.
- [x] `M.setup(theme_override)` accepts an optional `"dark"|"light"`
      argument. When present, it overrides `get_os_theme()`'s
      result. Existing no-arg callers are unchanged in behavior.
- [x] `M.set_theme(theme)` produces exactly one emit per
      invocation, even when `theme` differs from the current
      `vim.o.background`. Verified by a new spec case that pins
      `vim.g.colors_name = "solarized"` and `vim.o.background = "dark"`
      in `pre_case`, registers a counting subscriber, calls
      `M.set_theme("light")`, and asserts the count is exactly 1.
- [x] `M.toggle()` produces exactly one emit per invocation.
      Verified by the same FLAG-32-A fix (clears `colors_name`,
      calls `M.setup(next)`); same-direction toggle was already
      covered by the carry-forward cases from #33.
- [x] FLAG-32-A is resolved in parent #32. The flag's status is
      updated from "Proposed resolution for #34" to "Resolved in
      #34" with a one-line note pointing to the chosen alternative
      and the new spec case. Edit happens in this sub-issue.
- [x] `./tests/run` exits 0 on the whole suite — including the
      new `set_theme` single-emit case. Total case count: 125
      (increased by 1 from #33's 124).
- [x] `PATH=/usr/bin:/bin ./tests/run` exits 0 equivalent —
      verified as `PATH=/opt/homebrew/bin:/usr/bin:/bin` (nvim
      present, `defaults` absent); `vim.fn.has` stub ensures no
      shell-out to `defaults` during tests.
- [x] No reaching into local functions or monkey-patching
      internals beyond the sanctioned per-test
      `vim.api.nvim_set_hl` / `vim.cmd` / `vim.defer_fn` /
      `vim.fn.has` swaps. (Carry-forward.)
- [x] **Resolved-through-implementation decision recorded in
      AAR:** FLAG-32-A → Alternative A. `vim.g.colors_name = nil`
      before `M.setup(theme_override)` suppresses the reapply path;
      suppression is named at the call site, no hidden state.
- [x] **Resolved-through-implementation decision recorded in
      AAR:** latent "user choice loses to OS state" bug fixed as a
      side effect of the `theme_override` arg to `M.setup`.

## Proposed tests

Extend `tests/colors/solarized_subscribe_spec.lua` with one new
case:

7. `set_theme emits exactly once when background flips` — in
   `pre_case`, set `vim.o.background = "dark"` and
   `vim.g.colors_name = "solarized"`. Register a counting
   subscriber. Call `solarized.set_theme("light")`. Assert the
   count is 1. This case directly exercises FLAG-32-A's
   resolution path. The pre-existing 6 cases continue to pin
   `vim.o.background = "dark"` and call `set_theme("dark")` to
   probe the same-background path, which remains a single-emit
   scenario.

The existing per-case fakes (`vim.api.nvim_set_hl`, `vim.cmd`,
`vim.defer_fn`, `vim.fn.has`) cover the new case without
changes — `vim.cmd("redraw!")` lands on the no-op fake, and
`vim.defer_fn` is no longer called inside `setup`/`set_theme`/
`toggle` because the LualineRefresh defer blocks are deleted.

If the chosen FLAG-32-A alternative is A, the spec sets
`vim.g.colors_name = "solarized"` in `pre_case` and the
`set_theme` call clears it before the new setup runs; the test
confirms by reading `vim.g.colors_name` after the call (must be
back to `"solarized"`). This is a passive observation, not a
new public API.

## Affected artifacts

- **`lua/colors/solarized.lua`**:
  - `M.setup` gains optional `theme_override` parameter (small
    edit at the top of the function).
  - The `vim.defer_fn(... LualineRefresh ...)` block at the end
    of `M.setup` (currently lines ~519–524) is deleted.
  - The `vim.defer_fn(... LualineRefresh ...)` block in
    `M.toggle` (currently lines ~543–550) is deleted.
  - The `print("Solarized: Toggling from", ...)` line in
    `M.toggle` (currently line ~535) is deleted.
  - The `vim.defer_fn(... LualineRefresh ...)` block in
    `M.set_theme` (currently lines ~563–567) is deleted.
  - `M.set_theme` body changes per the chosen FLAG-32-A
    alternative — under A, it clears `vim.g.colors_name` and
    calls `M.setup(theme)` instead of setting `vim.o.background`
    explicitly.
  - `M.toggle` body changes analogously under A — clears
    `vim.g.colors_name` and calls `M.setup(opposite)` instead of
    setting `vim.o.background` explicitly.
  - `vim.cmd("redraw!")` in both functions is preserved.
- **`lua/plugins/lualine.lua`**:
  - The `OptionSet`/`background` autocmd block (currently lines
    ~135–149) is deleted.
  - The `ColorScheme` autocmd block (currently lines ~151–163)
    is deleted, including the live `print("ColorScheme changed
    to:", vim.g.colors_name)` at line ~155.
  - The commented `-- print(...)` line inside `LualineRefresh`'s
    body (currently line ~170) is deleted; the command itself
    is preserved.
- **`tests/colors/solarized_subscribe_spec.lua`** — append one
  new case (the seventh) per the test plan above.
- **`context/cycles/03-config-deepening/issues/32-theme-subscribe-seam/issue.md`**
  — FLAG-32-A's "Proposed resolution for #34" updated to
  "Resolved in #34: <chosen alternative>", recorded as part of
  this sub-issue's closure.

No edits to `lua/config/autocmds.lua`, `lua/colors/os_theme.lua`
(does not exist yet), the inlined `get_os_theme`, the
highlight-tables, or any other file.

## Dependencies

- **Sub-issue #33 (closed)** — provided the subscribe seam,
  the per-test fake pattern, and the FLAG-32-A description.
  This sub-issue extends `solarized_subscribe_spec.lua` directly
  and trusts the registry/payload decisions (Alt. A + C1) made
  in #33's AAR.
- **Cycle 03 parent #22 (A) closure** — the
  `LualineRefresh` user command preservation rule lives in
  parent #22's AAR and is honored here.
- **No dependency on later sub-issues under parent #32.** #35
  (`os_theme` extraction) and #36 (closure) build on #34's
  reaction-mechanism collapse; #34 does not depend on them.
- **No dependency on parent C.**
