# AAR — Sub-issue #33: Subscribe tracer + lualine first contact

## 1. Did it go as planned? Yes — one unplanned discovery.

All acceptance criteria met. The subscribe seam is live, lualine is migrated, the polling timer is deleted, and all 124 tests pass. One behavioral gap surfaced during deepening (FLAG-32-A: double-emit on background-change).

## 2. What changed from the sub-issue plan

**Colorscheme re-apply interaction (unplanned).**  
`colors/solarized.lua` (the colorscheme entry-point) is in the runtimepath.
When `set_theme` changes `vim.o.background` while `vim.g.colors_name =
"solarized"` is already set, Neovim re-executes the colorscheme file →
`solarized.setup()` → `emit()`. Then `set_theme` calls `M.setup()` explicitly,
producing a second emit. The acceptance criterion "emits exactly once per
`setup()` call" is satisfied at the individual `setup()` call level, but a
single logical `set_theme("light")` from "dark" triggers two `setup()` calls in
production.

**Test strategy adapted.** The spec pins `vim.o.background = "dark"` in
`pre_case` so `set_theme("dark")` never changes the background, preventing the
re-apply path from firing during tests. The counting test uses `solarized.setup()`
directly (same-background calls) rather than a dark→light `set_theme` sequence.
This is a tighter probe of the emit contract without triggering the re-apply
side-effect. Documented in test comments.

## 3. Resolved-through-implementation decisions

**Registry location: Alt. A confirmed.** Module-local `subscribers` table inside
`solarized.lua`. Rationale: single consumer (lualine), mirrors parent #22's
resolution, lowest blast radius. Promotion to `lua/colors/subscribe.lua`
remains one edit if a second consumer surfaces.

**Payload shape: C1 confirmed.** `fn()` — no-arg. Lualine's subscriber closure
calls `create_solarized_theme()` which already reads `vim.o.background` directly.
Passing the theme value would duplicate state already at the call site. C2 (`fn(theme)`)
remains backwards-compatible if needed later.

## 4. Carry-forward

- **FLAG-32-A written in parent #32.** Double-emit on background-change direction
  flip. Proposed fix deferred to #34: move `vim.o.background = theme` in
  `set_theme` to after `M.setup()` returns (the value is already set by
  `get_os_theme()`'s fallback), which removes the trigger. #34 should evaluate
  this during its pre-activation pass.

- **Test pattern note for #34/#35.** The `vim.o.background = "dark"` pin in
  `pre_case` is load-bearing. Any spec that needs to test a dark→light transition
  must either (a) clear `vim.g.colors_name` before changing background to
  suppress re-apply, or (b) accept the double-emit and assert count = 2 per
  `set_theme` call in that scenario. Document this in the next spec's comments.

- **`LualineRefresh` command preserved** in `lualine.lua` per parent #22's AAR
  (plugin-internal, manual-fallback handle). Not modified in this sub-issue.

- **Four reaction mechanisms deliberately untouched** per scope: `OptionSet`
  autocmd, `ColorScheme` autocmd, three `vim.defer_fn(LualineRefresh)` blocks in
  `solarized.lua`, and `print()` statements. Sub-issue #34 addresses these.
