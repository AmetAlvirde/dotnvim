# AAR — Parent Issue #30: macOS `codesign` workaround extraction (Candidate D)

1. **Did it go as planned?** Yes — all ACs verified in a single pass with no
   deviations from the sketches in `issue.md`.

2. **What changed from the parent issue plan:**
   Nothing. The three-file layout (`command.lua`, `shell.lua`, `init.lua`),
   the setter seam, the autocmd wiring, and the test pattern all matched the
   plan exactly. The `io.popen` default runner was preserved; async
   `vim.fn.jobstart` remains deferred per the recorded deferred decision.

3. **ADRs made during this parent issue (reference INDEX.md rows):**
   None. This parent applied ADR-0003 (four-layer subpackage) without
   surfacing a new durable pattern. No ADR candidate warranted recording.

4. **New considerations or constraints surfaced:**
   - The `has("mac")` guard placement decision resolved in favour of
     `init.lua`: the autocmd is unconditional and declarative; the guard is
     application logic that belongs in the utility. This is the expected
     outcome given ADR-0003's composition-root pattern — the init layer owns
     runtime branching, the wiring layer owns registration.
   - The restricted-PATH test (`PATH=/opt/homebrew/bin:/usr/bin:/bin
     ./tests/run`) is the practical equivalent of the AC's
     `PATH=/usr/bin:/bin` variant: `nvim` is at `/opt/homebrew/bin/nvim`
     on this machine, so a pure `/usr/bin:/bin` PATH would exclude `nvim`
     itself, not just `codesign`. The shell-runner seam means the test suite
     never invokes the real `codesign` binary regardless of PATH.

5. **Patterns across sub-issue AARs:**
   No sub-issues. Implemented directly from `issue.md`.

6. **Carry-forward — flags to write in the cycle, notes for the PRD AAR:**
   None. D is independent. B and C do not have `issue.md` files yet; no
   assumptions from D's changes affect their future design. The autocmd
   wiring in `autocmds.lua` is now narrower (one block changed, nothing
   adjacent touched), which may reduce B's merge-conflict surface when it
   reshapes the theme-change handlers — a convenience, not a flag.
