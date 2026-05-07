# AAR — Parent Issue #32: Theme-change subscribe seam (Candidate B)

## 1. Did it go as planned? Yes — one unplanned discovery in #33, cleanly resolved in #34.

All acceptance criteria are `[x]`. The four-sub-issue arc executed in the
planned sequence (#33 → #34 → #35 → #36) with no sequencing changes and no
scope expansion outside the defined blast radius. The single unplanned event
(FLAG-32-A: double-emit on background-change direction flip) surfaced in #33
and was resolved in #34 as proposed.

## 2. What changed from the parent issue plan

**FLAG-32-A (double-emit) surfaced in #33 and resolved in #34.**  
When `set_theme` changes `vim.o.background` while `vim.g.colors_name =
"solarized"` is already set, Neovim re-executes the colorscheme file, producing
a first `emit()`. `set_theme` then calls `M.setup()` explicitly, producing a
second. Alternative A was chosen: `set_theme` and `toggle` clear
`vim.g.colors_name = nil` before calling `M.setup(theme_override)`, suppressing
the re-apply path. As a side effect, the latent "user choice loses to OS state"
bug in `set_theme` was fixed — `set_theme("dark")` now passes `theme_override`
to `setup`, so `os_theme.detect()` is bypassed.

**`os_theme` extraction (Candidate E / #35) collapsed into a single file.**  
The ADR-0003 four-layer split (`command.lua`, `shell.lua`, `parsers.lua`,
`presenter.lua`) collapsed to a single `lua/colors/os_theme.lua`. The command
is one literal string and the parser is one `:match`; no presenter is needed.
Precedent from parent #30's latitude on trivial commands was applied.

**FocusGained was dead code after #35 until #36 added `os_theme.refresh()`.**  
After #35 landed the cache, the FocusGained handler was calling `setup()`
against a stale cached value — no shell-out, no emit change. This was the
expected design space the sub-issue #36 was always scoped to address. The
reshape (`refresh()` before `setup()`) was the proposed default and was
confirmed.

## 3. ADRs made during this parent issue

No new ADR rows added to `context/adr/INDEX.md` during this parent issue.

- **ADR-0003** (runner-seam shape, established in parent #30) was applied to
  `os_theme`. The collapse-vs-split decision (Alt C: single file, runner takes
  `cmd`) is recorded in sub-issue #35's AAR and is a documented application of
  ADR-0003's latitude clause, not a revision.
- **ADR-0004** — deferred. See open Q #4 resolution below.

## 4. Open-question resolutions

### Open Q #3 — subscribe-registry generalization

**Resolution: scoped strictly to `colors.solarized.subscribe`.**  
Lualine remains the only consumer in cycle 03. No second consumer surfaced
during #33–#36. The registry is a module-local table inside `solarized.lua`
(per #33's registry-location decision, Alt A). Promotion to a shared
`lua/colors/subscribe.lua` remains one edit if a second consumer surfaces in a
future cycle.

Default expectation from cycle PRD open Q #3: "scope strictly unless a second
consumer surfaces." Confirmed.

### Open Q #4 — ADR-0004 candidate for the subscribe-registry pattern

**Resolution: deferred to cycle 03 PRD close.**  
After parent C lands and the cycle closes, the PRD close considers whether
registrar (#22) + subscribe (#33) + os_theme runner (#35) form a coherent
enough family of "publicly named seams over module-local state" to merit a
shared ADR-0004. Premature to write during the closing sub-issue of a parent
whose whole purpose was collapsing mechanisms.

Default expectation from cycle PRD open Q #4: "defer to cycle 03 PRD close."
Confirmed.

## 5. Patterns across sub-issue AARs

**Every sub-issue executed on the first design proposal.** No Alternative B or
C was chosen on any question (#33 registry-location, #33 payload-shape,
#34 FLAG-32-A, #35 layout, #36 both autocmds). The interface-design work in
each sub-issue was predictive.

**The `theme_override` arg and `vim.g.colors_name` nil-clear are load-bearing.**  
Both came from FLAG-32-A. They are the subtlest behavioral change in the arc —
the other deletions (polling timer, three autocmds, three deferred blocks,
prints) were mechanical. Future maintainers touching `set_theme` or `setup`
should read the #34 AAR for the suppression rationale.

**`os_theme.refresh()` is the only cache-bypass seam.**  
Its purpose is exactly the FocusGained use case: one call site that needs to
force a re-read. If a second use case for cache bypass appears, `refresh()`
covers it without interface change.

## 6. Carry-forward into parent C

- **No flags to write.** Parent C (highlight decomposition) builds on the clean
  module surface left by B. No B artifact is in a state that creates a
  correctness assumption for C.
- **ADR-0004 consideration.** At cycle 03 PRD close, evaluate whether
  registrar (#22) + subscribe seam (#33) + os_theme runner (#35) share enough
  structure for a single "module-local seam with public setter" ADR. The three
  sub-issue AARs (#33 registry-location, #34 FLAG-32-A, #35 Alt-C layout) are
  the evidence base.
- **`os_theme.detect()` is the call site in `solarized.setup()`.** Parent C
  (highlight decomposition) will encounter this coupling if it restructures
  `setup()`. No action needed now; flag for parent C's pre-activation if its
  scope touches `setup()` internals.
