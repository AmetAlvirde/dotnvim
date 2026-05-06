## Sub-PRD — Theme-change subscribe seam (Candidate B)

> Translated to `issue.md`. This sub-PRD records the product-level intent --
> user stories and dependencies. Update `issue.md` for ongoing technical work.
> Update this file only if the underlying user stories themselves change.

Third parent issue of cycle `03-config-deepening`, per the resolved
sequencing in the cycle PRD's open question #1 (A → D → B → C).
Carries the cycle PRD's Candidate B goal — collapsing the five-channel
theme-reaction wiring between `colors.solarized` and
`plugins.lualine` into one `subscribe(fn)` signal — and folds in
Candidate E (extraction of `get_os_theme` to `lua/colors/os_theme.lua`
with a runner seam and cached last value) per the cycle PRD's
resolution that E lives under B's surface.

## Scope

Introduce `colors.solarized.subscribe(fn) -> unsubscribe_fn` and a
single emit point that fires once per theme apply (`setup()`,
`set_theme()`, `toggle()`). Lualine subscribes once and reacts to that
signal. The currently-extant five reaction mechanisms collapse:

1. The `vim.loop.new_timer()` polling timer in `lua/plugins/lualine.lua`
   (lines ~169–180) is deleted.
2. The `OptionSet`/`background` autocmd in `lua/plugins/lualine.lua`
   (lines ~128–141) is deleted.
3. The `ColorScheme` autocmd in `lua/plugins/lualine.lua`
   (lines ~144–155) is deleted.
4. The three `vim.defer_fn(... LualineRefresh ...)` blocks in
   `lua/colors/solarized.lua` (lines ~496–500, ~519–526, ~539–544) are
   deleted. Subscribe replaces them.
5. The `FocusGained` and `VimEnter` autocmds in `lua/config/autocmds.lua`
   (lines ~104–111, ~114–121) are evaluated as triggers (not consumers
   of the subscribe signal). Either retained with a recorded reason —
   they re-call `setup()` to detect a system theme flip on macOS — or
   reshaped to call a more intentional `os_theme`-aware refresh path.

Stray `print()` debug statements in the theme-change path
(`solarized.lua` lines ~511, ~520, ~524; `lualine.lua` lines ~147,
plus the commented-out prints that are noise of the same provenance)
are removed.

Candidate E lands under this parent: `lua/colors/os_theme.lua` exists
exposing `M.detect() -> "dark"|"light"` with an ADR-0003-style
runner seam (`M.set_runner(fn)` / `M.reset_runner()`) and a cached
last value. The `defaults read AppleInterfaceStyle` shell-out fires
on cache miss or explicit refresh — not on every `FocusGained`.
`solarized.setup()` consults `os_theme.detect()` instead of the
currently-inlined `get_os_theme` function.

The 18 user commands keep their names and argument shapes. The three
`:Solarized*` commands keep their observable behavior — the
statusline reflecting the active palette after `:SolarizedToggle`,
after a system theme flip on macOS, and after `FocusGained` is
preserved. The internal mechanism collapses; the externally
observable behavior does not.

Out of scope for this parent issue:

- Generalizing the subscribe registry into a configuration-wide event
  bus. Per cycle PRD open question #3, scope strictly to
  `colors.solarized.subscribe`. If a second consumer surfaces during
  implementation, generalize then; otherwise defer.
- ADR-0004 for the subscribe-registry pattern. Per cycle PRD open
  question #4, defer the decision to PRD close — premature ADRs
  codify guesses, per the ADR-0003 precedent from cycle 02.
- Refactoring any other autocmd handler in `lua/config/autocmds.lua`
  beyond the two solarized handlers (`VimEnter`, `FocusGained`).
  Per cycle PRD non-goal #8.
- Refactoring `lua/colors/solarized.lua`'s highlight tables. That is
  Candidate C's surface (next parent issue), not B's.
- Adding new theme variants, new highlight groups, or new lualine
  sections. Only existing surfaces are reshaped.
- Async or `vim.fn.jobstart`-based shell execution for the
  `os_theme` runner. The current `io.popen` synchronous path matches
  observable behavior; async is a future cycle's call if blocking
  proves a problem.

## User stories

From the cycle PRD (story 2):

> As a maintainer auditing how the statusline reacts to a theme flip,
> I want exactly one named place that emits the event and one named
> place that subscribes, so that I can reason about the wiring
> without scanning five mechanisms across three files.

From the cycle PRD (story 5, sub-slice):

> As a maintainer running the test suite headlessly, I want each
> extracted seam (subscribe registry, `os_theme` runner) to be
> exercised by at least one unit test against `./tests/run`, so that
> a regression in any of these surfaces cannot reach the
> configuration silently.

From the cycle PRD (story 6, sub-slice):

> As a maintainer of the wiring files at cycle close, I want
> `lua/plugins/lualine.lua` to read top-to-bottom as a declarative
> spine — initial setup, one subscribe, the lualine config — without
> a polling timer, two reaction autocmds, and a plugin-internal
> command tangled together.

## Dependencies

- **ADR-0003** — governs the four-layer subpackage shape for the
  `os_theme` extraction (Candidate E). Likely collapsed: command
  building is trivial enough that `os_theme.lua` may carry runner
  seam inline rather than splitting `command.lua` / `shell.lua`.
  Resolved in the first sub-issue's design pass.
- **Cycle 03 parent #22 (A) closure** — established the fake-the-API
  test pattern (swap a `vim.api.*` call for a fake in `pre_case`,
  restore in `post_case`). B reuses that pattern for its subscribe
  contract test and for its `os_theme` runner-seam test. Closed.
- **Cycle 03 parent #30 (D) closure** — proved the ADR-0003
  setter-seam pattern works on a new module type with a shell
  runner. B's `os_theme` extraction follows the same shape.
  Closed.
- **`lua/colors/solarized.lua`** — gains `subscribe`/emit; loses
  three deferred-fn LualineRefresh blocks and stray prints; loses
  inlined `get_os_theme` in favour of `os_theme.detect()`.
- **`lua/plugins/lualine.lua`** — gains one subscribe call; loses
  the polling timer, two reaction autocmds, and stray prints. The
  plugin-internal `LualineRefresh` user command is preserved (out
  of registrar contract per parent #22, and externally observable
  for fallback / debug).
- **`lua/config/autocmds.lua`** — `VimEnter` and `FocusGained`
  solarized autocmds either retained-with-reason or collapsed; no
  other autocmd handler is touched (cycle PRD non-goal #8).
- **`lua/colors/os_theme.lua`** — new module, created in this
  parent issue (Candidate E folded in). Owned entirely by this
  parent.
- No dependency on parent C. C is sequenced after B because
  highlight-section decomposition is easier once theme-change
  handlers have consolidated to one signal.
