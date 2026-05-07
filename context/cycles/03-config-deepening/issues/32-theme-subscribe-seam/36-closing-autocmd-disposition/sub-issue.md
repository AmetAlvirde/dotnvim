# Sub-issue #36 — Closing: autocmd disposition + open-question resolutions

GitHub issue: #36. Fourth and closing sub-issue under parent #32 (Candidate B —
theme-change subscribe seam) of cycle `03-config-deepening`. After this sub-issue
closes, parent #32's `aar.md` lands as a sibling and the cycle moves on to
parent C.

## Description

Decide the disposition of the two solarized autocmds in
`lua/config/autocmds.lua` (`VimEnter` lines 104–111, `FocusGained` lines
114–121) given the cached `os_theme.detect()` flow that landed in #35. Record
the two cycle-PRD open-question resolutions that this parent has been carrying
(subscribe-registry generalization — open Q #3; ADR-0004 candidate — open Q
#4). Verify all parent #32 acceptance criteria are checked. Write parent #32's
sibling `aar.md`.

The trigger this sub-issue addresses is one each handler does not yet meet
cleanly:

- **VimEnter handler** re-runs `solarized.setup()` after the colorscheme has
  already been loaded once by `lua/config/options.lua:34`
  (`vim.cmd("colorscheme solarized")`). The first `setup()` runs before
  `lazy.nvim` finishes loading lualine. Lualine's subscribe registration
  happens inside its `config` block, which lazy.nvim invokes after the
  colorscheme load. Without VimEnter's re-`setup()`, lualine misses the
  startup emit. The handler today happens to cover this gap silently — but
  the reason is not recorded.
- **FocusGained handler** re-runs `solarized.setup()` to detect a system
  theme flip when the user returns to nvim. After #35, `os_theme.detect()`
  is cached. Without an `os_theme.refresh()` call before `setup()`, the
  handler reads the stale cached value and emits no behavior change — it
  is dead code. Either the handler is reshaped to call `os_theme.refresh()`
  before `setup()`, or it is deleted (regressing observable behavior on
  system theme flips).

After this sub-issue:

- The two solarized autocmds in `lua/config/autocmds.lua` carry a `desc`
  field recording the reason each is retained (or one/both are deleted with
  the rationale captured in the AAR).
- `FocusGained` calls `require("colors.os_theme").refresh()` before
  `require("colors.solarized").setup()`, so the handler does the work its
  name implies.
- Parent #32's three remaining `[ ]` ACs (autocmd disposition, subscribe
  generalization, ADR-0004 candidate) are all `[x]`.
- Parent #32's sibling `aar.md` exists, recording the four-sub-issue arc and
  any cross-cutting carry-forward into parent C.

No other autocmd handler in `lua/config/autocmds.lua` is touched
(cycle PRD non-goal #8). No edits to `lua/colors/solarized.lua`,
`lua/colors/os_theme.lua`, `lua/plugins/lualine.lua`, or any of their specs.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `colors.solarized.setup` (called from autocmds) | In-process | Already covered by `solarized_subscribe_spec.lua`. No new spec required for the autocmd wiring itself — autocmds run in the editor session, not under `mini.test`. |
| `colors.os_theme.refresh` (called from FocusGained) | In-process | Already covered by `os_theme_spec.lua` case 7 (`refresh: clears cache so next detect re-runs runner`). The autocmd uses `refresh` as its public seam; that seam is exercised. |
| `vim.api.nvim_create_autocmd` | True external (Neovim API) | Not testable under `mini.test` without a child neovim. Verified by grep + manual exercise in a live editor session (golden-path: open nvim, flip macOS appearance, confirm statusline updates). |
| `vim.g.colors_name` | True external (Neovim runtime state) | Read-only guard inside the handler; no test coverage needed beyond the existing handler shape. |
| `lazy.nvim` plugin load order | Collaborator-owned (external) | Not under test. The VimEnter retention rationale rests on the documented lazy.nvim behavior of running `config` blocks after the colorscheme directive. |

No new specs land in this sub-issue. The existing 132 cases continue to pass.

## Interface design

The "interface" here is two `vim.api.nvim_create_autocmd` blocks and the
`desc` field on each. Three internal questions.

1. **VimEnter handler** — retain (with `desc`), reshape, or delete.
2. **FocusGained handler** — retain (with `desc` and `os_theme.refresh()`),
   reshape into a different trigger, or delete.
3. **Subscribe-registry generalization (open Q #3) and ADR-0004 candidate
   (open Q #4)** — record the resolution in parent #32's AAR.

### Question 1 — VimEnter handler

#### Alternative A — retain with `desc`

```lua
autocmd("VimEnter", {
  desc = "Re-apply solarized after lazy.nvim plugin load so subscribers "
      .. "(lualine) registered post-colorscheme receive the startup emit.",
  callback = function()
    if vim.g.colors_name == "solarized" then
      require("colors.solarized").setup()
    end
  end,
  group = solarized_group,
})
```

**Pros:** Preserves the silent guarantee that lualine receives at least one
emit after registering its subscriber. Adds a `desc` so a future maintainer
can read the reason without spelunking lazy.nvim's load order. Cache-cheap
on the second `setup()` — `os_theme.detect()` returns the cached value, so
the only repeated work is the highlight-table application, which is
already idempotent.

**Cons:** Two `setup()` calls per startup (one from `colors/solarized.lua`,
one from VimEnter). The second call is observable as a subscribe emit that
arrives between cold init and first user input. Lualine's subscribe
callback wraps `setup_lualine()` in a `vim.defer_fn(..., 100)`, so the
visible effect is bounded.

#### Alternative B — delete

Trust lualine's `config` block (`setup_lualine()` is called directly inside
it, before `solarized.subscribe(...)`) to handle initial paint. The
startup emit lualine misses is benign because it would have re-applied a
state lualine has already applied.

**Pros:** One fewer redundant `setup()` per startup. The autocmds file
shrinks by one block.

**Cons:** Couples correctness to lualine's `config` block doing the right
thing on cold init. If a future subscriber lands that does NOT do its own
initial paint inside its `config` block, the missed startup emit becomes a
real bug. Re-introducing VimEnter later would require rediscovering the
reason it existed — exactly the rot the cycle PRD's "deepening" goal warns
against.

#### Alternative C — reshape into a `User SolarizedReady` autocmd emitted by lualine

Promote the startup-coverage problem into an explicit named event:
lualine emits `User SolarizedReady` after registering, and `solarized.lua`
subscribes to that to re-emit. Inverts the dependency.

**Pros:** Removes the VimEnter timing question entirely.

**Cons:** Adds a new mechanism to a parent that just collapsed five into
one. Speculative — no second subscriber in cycle 03 motivates it. Violates
the "scope strictly to `colors.solarized.subscribe`" resolution from open
Q #3 (recorded under question 3 below).

#### Chosen (proposed; final in AAR)

**Alternative A.** Retain with a one-line `desc` recording the
lazy-load-order reason.

**Reason for A:** Preserves the silent guarantee, makes the reason
self-documenting on the next read, and the cost (one cache-hot `setup()`
re-call at VimEnter) is negligible. The cycle PRD's deepening goal is met
by *naming* the implicit reason, not by removing the mechanism.

**Rejected B:** Couples correctness to a single subscriber's `config` block
shape. Re-introducing VimEnter later costs more than naming it now.

**Rejected C:** Adds a new mechanism in the closing sub-issue of a parent
issue whose whole purpose was collapsing mechanisms. Speculative without a
second subscriber.

### Question 2 — FocusGained handler

#### Alternative A — retain with `desc` and `os_theme.refresh()` before `setup()`

```lua
autocmd("FocusGained", {
  desc = "Refresh os_theme cache and re-apply solarized so a system "
      .. "theme flip while nvim was unfocused is detected on focus return.",
  callback = function()
    if vim.g.colors_name == "solarized" then
      require("colors.os_theme").refresh()
      require("colors.solarized").setup()
    end
  end,
  group = solarized_group,
})
```

**Pros:** Preserves observable behavior that the sub-PRD pinned ("the
statusline reflecting the active palette after a system theme flip on
macOS is preserved"). The handler now does what its name implies: refresh
the OS read, then re-apply. Cache-aware: every `FocusGained` does cost one
shell-out, but only one — without the refresh-then-setup pairing the cache
makes the handler dead, which is worse.

**Cons:** A shell-out fires on every focus return, even when no theme
flipped. The shell-out is `defaults read -g AppleInterfaceStyle` (~1ms).
Observable cost is bounded. If profiling later surfaces this as a real
hotspot, the runner can grow a "did the value actually change" path —
out of scope here.

#### Alternative B — delete

Accept the regression. After deletion, system theme flips while nvim is
unfocused are not detected; the user must manually run `:SolarizedToggle`
or restart nvim.

**Pros:** Removes the per-focus shell-out. The autocmds file shrinks.

**Cons:** Regresses observable behavior the sub-PRD explicitly preserves.
Out of scope: cycle PRD non-goal #4 is "no observable regressions in
the 18 user commands." The system-theme-flip behavior is not user-command,
but the spirit of the non-goal applies.

#### Alternative C — replace with a `BufEnter` or `CursorHold`

Same shape as A but a different trigger. `BufEnter` fires on every buffer
switch (too noisy); `CursorHold` fires after `updatetime` of inactivity
(unreliable for the use case).

**Pros:** Possibly less I/O.

**Cons:** None of the alternative triggers match the use case
("user returned to nvim after using the system theme picker") as cleanly
as `FocusGained`.

#### Chosen (proposed; final in AAR)

**Alternative A.** Retain with `desc` and `os_theme.refresh()` before
`setup()`.

**Reason for A:** Preserves the observable behavior the sub-PRD pinned.
Names the reason the handler exists. Pairs `os_theme.refresh()` with
`setup()` in the only call site that needs cache-bypass, which is exactly
the use case `M.refresh()` was extracted for in #35.

**Rejected B:** Regresses observable behavior.

**Rejected C:** Wrong trigger for the use case.

### Question 3 — Open-question resolutions for parent #32 AAR

Two cycle-PRD open questions resolve at parent close, not at this
sub-issue's close. The mechanism is: the AAR records the resolution; this
sub-issue's closure produces the AAR.

#### Open Q #3 — subscribe-registry generalization

The cycle PRD asks whether `colors.solarized.subscribe` should generalize
into a configuration-wide event bus. Default: scope strictly to
`colors.solarized.subscribe` unless a second consumer surfaced.

**Resolution:** Scope strictly to `colors.solarized.subscribe`. Lualine
remains the only consumer in cycle 03. No second consumer surfaced
during #33–#35 implementation. No generalization. The registry is a
module-local table inside `solarized.lua` (per #33's design decision).

#### Open Q #4 — ADR-0004 candidate

The cycle PRD asks whether the subscribe-registry pattern warrants an ADR.
Default: defer to cycle 03 PRD close, where the family of seams (registrar
from parent A, subscribe from parent B) may share an ADR.

**Resolution:** Defer. After parent C lands and the cycle closes, the PRD
close considers whether registrar (#22) + subscribe (#33) + os_theme
runner (#35) form a coherent enough family of "publicly named seams over
module-local state" to merit a shared ADR-0004. Premature now.

Both resolutions land in parent #32's `aar.md` verbatim, with the
default-expectation language from the cycle PRD intact for traceability.

## Acceptance criteria

- [ ] `lua/config/autocmds.lua`'s `VimEnter` solarized autocmd carries a
      `desc` field recording the reason it is retained (lazy.nvim load
      order — subscribers registered after the colorscheme directive
      receive the VimEnter emit). Verified by reading the file.
- [ ] `lua/config/autocmds.lua`'s `FocusGained` solarized autocmd carries
      a `desc` field recording the reason it is retained (system theme
      flip detection on focus return) AND calls
      `require("colors.os_theme").refresh()` before
      `require("colors.solarized").setup()` in its callback body.
      Verified by reading the file.
- [ ] No other autocmd handler in `lua/config/autocmds.lua` is modified in
      this sub-issue. Verified by `git diff lua/config/autocmds.lua`
      showing edits only inside the `SolarizedTheme` group block.
- [ ] `./tests/run` exits 0 on the whole suite. Total case count remains
      132 (#35's count); no specs are added or removed.
- [ ] `PATH=/opt/homebrew/bin:/usr/bin:/bin ./tests/run` exits 0.
- [ ] Manual smoke check in a live nvim session: open nvim with the
      configuration loaded, confirm the statusline matches the active
      `vim.o.background`. Flip macOS appearance via System Settings;
      switch focus away and back to nvim; confirm the statusline updates
      to the new theme. Recorded in AAR. (No automated coverage — the
      autocmd-driven flow is not testable under `mini.test`.)
- [ ] All parent #32 acceptance criteria are `[x]`. Verified by reading
      `context/cycles/03-config-deepening/issues/32-theme-subscribe-seam/issue.md`
      and confirming no `[ ]` checkboxes remain.
- [ ] Sibling `aar.md` exists at
      `context/cycles/03-config-deepening/issues/32-theme-subscribe-seam/aar.md`,
      written per the `sdp-close` parent-AAR shape. Records the
      four-sub-issue arc, the two open-question resolutions (subscribe
      generalization, ADR-0004 candidate), the FLAG-32-A resolution
      provenance from #34, and any carry-forward into parent C.
- [ ] **Resolved-through-implementation decision recorded in parent AAR:**
      subscribe-registry generalization (cycle PRD open Q #3) — scoped
      strictly to `colors.solarized.subscribe`, no second consumer
      surfaced in cycle 03.
- [ ] **Resolved-through-implementation decision recorded in parent AAR:**
      ADR-0004 candidate for the subscribe-registry pattern (cycle PRD
      open Q #4) — deferred to cycle 03 PRD close, where the family of
      seams (registrar from A, subscribe from B, os_theme runner from D's
      sibling work in #35) may share an ADR.
- [ ] **Resolved-through-implementation decision recorded in this
      sub-issue's AAR:** VimEnter and FocusGained autocmd disposition.
      Default expectation: Alternative A on both — retain with `desc`,
      pair `FocusGained` with `os_theme.refresh()`. If implementation
      surfaces a reason to flip A→B or A→C on either, the sub-issue AAR
      records the reason.

## Proposed tests

No new specs. The two seams the autocmds cross are already covered:

- `os_theme.refresh()` cache-clear behavior: covered by case 7 in
  `tests/colors/os_theme_spec.lua`.
- `solarized.setup()` single emit per call: covered by cases in
  `tests/colors/solarized_subscribe_spec.lua`.

The autocmd wiring itself (registration, callback firing on
`VimEnter`/`FocusGained`) is not under `mini.test` coverage in this
configuration. A child-neovim spec would be needed and is out of scope per
the parent's "no `mini.test.new_child_neovim`" constraint.

The manual smoke check listed in the acceptance criteria is the only
verification of the live autocmd flow.

## Affected artifacts

- **`lua/config/autocmds.lua`**:
  - `VimEnter` handler (lines 104–111): add `desc` field, no behavior
    change.
  - `FocusGained` handler (lines 114–121): add `desc` field, prepend
    `require("colors.os_theme").refresh()` to the callback body.
  - No other handlers touched.
- **`context/cycles/03-config-deepening/issues/32-theme-subscribe-seam/issue.md`**:
  - The three remaining `[ ]` ACs (autocmd disposition, subscribe
    generalization, ADR-0004 candidate) move to `[x]`. Edits happen as
    part of this sub-issue's closure.
- **`context/cycles/03-config-deepening/issues/32-theme-subscribe-seam/aar.md`**
  (new file) — parent #32's sibling AAR. Records the arc, open-question
  resolutions, FLAG-32-A provenance, and carry-forward.
- **`context/cycles/03-config-deepening/issues/32-theme-subscribe-seam/36-closing-autocmd-disposition/aar.md`**
  (new file) — this sub-issue's AAR. Records the autocmd-disposition
  decisions (Alternatives A on both, or any deviation surfaced during
  implementation) and the manual smoke check result.

No edits to `lua/colors/solarized.lua`, `lua/colors/os_theme.lua`,
`lua/plugins/lualine.lua`, `lua/config/options.lua`,
`lua/config/commands.lua`, or any spec file. No edits to highlight tables,
the `LualineRefresh` user command, or any other autocmd handler in
`lua/config/autocmds.lua`.

## Dependencies

- **Sub-issue #35 (closed)** — landed `os_theme.refresh()`, the entry
  point this sub-issue pairs with `setup()` in the `FocusGained` handler.
  Without #35, `FocusGained`'s reshape would have nothing to call.
- **Sub-issue #34 (closed)** — resolved FLAG-32-A so `setup()` emits
  exactly once per call; the `FocusGained` reshape inherits that
  guarantee. Sub-PRD's "statusline reflects the active palette after a
  system theme flip" hinges on the single-emit contract.
- **Sub-issue #33 (closed)** — established the subscribe contract that
  `setup()`'s emit drives. The reshape preserves this contract.
- **Cycle 03 parent #22 closure** — established the "named place to
  register, named place to fire" pattern that the autocmd `desc` fields
  honor. The `desc` field on each handler is the same shape of
  self-documentation parent #22's commands carry via `desc`.
- **Cycle 03 PRD non-goal #8** — "no other autocmd handler in
  `lua/config/autocmds.lua` is touched." Binding constraint on this
  sub-issue's blast radius.
- **Cycle 03 PRD open Q #3 and #4** — resolved in parent #32's AAR as
  part of this sub-issue's closure work, per the cycle PRD's
  resolve-through-implementation marker on each.
- **No dependency on parent C.** Parent C consumes parent #32's closure
  but does not feed back into this sub-issue.
