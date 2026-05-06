# AAR — Sub-issue #34: Lualine consolidation + print removal

## 1. Did it go as planned? Yes.

All acceptance criteria met. The four obsoleted reaction mechanisms are
deleted, all `print()` calls are gone, and FLAG-32-A is resolved. 125 tests
pass, including the new case 7.

## 2. What changed from the sub-issue plan

Nothing significant. Alternative A was the pre-designed choice and the
implementation matched the plan exactly. The `theme_override` argument also
fixed the latent "user choice loses to OS state" bug in `set_theme` as
anticipated in the interface design.

One wording clarification on the "restricted PATH" AC: `PATH=/usr/bin:/bin`
omits `nvim` itself (Homebrew install at `/opt/homebrew/bin`). The equivalent
verified was `PATH=/opt/homebrew/bin:/usr/bin:/bin` — nvim present, `defaults`
and `obsidian` absent — which satisfies the intent: `get_os_theme()` never
shells out during tests because `vim.fn.has` is stubbed to return 0.

## 3. Resolved-through-implementation decisions

**FLAG-32-A resolution: Alternative A confirmed.** `set_theme` and `toggle`
clear `vim.g.colors_name = nil` before calling `M.setup(theme_override)`. The
suppression is named at the call site, there is no hidden module-local state,
and the diff is minimal. Verified by spec case 7 (`set_theme: emits exactly
once when background flips`). Alternative B (re-entry guard) was rejected
because it hides the suppression and skips work the engine requested; the
sub-issue's design-it-twice section documents the full rejection rationale.

**Latent "user choice loses to OS state" bug: fixed as a side effect.** Before
this sub-issue, `set_theme("dark")` on macOS in light mode would call
`M.setup()` which called `get_os_theme()` → read the OS → return `"light"`,
silently overriding the caller's intent. The `theme_override` arg to `M.setup`
eliminates this: `set_theme("dark")` now calls `M.setup("dark")` and
`get_os_theme()` is bypassed. The fix is observable-correct — no AC explicitly
named it, but it aligns with the parent's "user-initiated theme change should
take effect" expectation.

## 4. Carry-forward

None. All #34 scope is self-contained. No new flags in the parent; no
divergence from closed work. Sub-issue #35 (`os_theme` extraction) builds on
the clean base left by #33 and #34.
