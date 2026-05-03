# AAR — Sub-issue #20: bookmark-parser slice + resolver seam

1. Did it go as planned? **Yes** — implemented exactly as specified; all 14
   proposed tests landed with no deviations.

2. What changed from the sub-issue plan:
   - Nothing material. The tracer bullet was case 3 (unquoted `.md` cell verbatim)
     rather than nil-input, to exercise the seam setup in the first contact. All
     14 named cases from the proposed-tests table are present and passing.
   - `bookmarks_verbose.txt` fixture: four lines (http+path, quoted-title+path,
     bare path, double-quoted path), yielding 4 non-nil results in order. Matches
     the fixture-test assertions exactly.
   - `parsers.lua` seam: `default_resolver`, `current_resolver`,
     `M.set_resolver(fn)`, `M.reset_resolver()` added after
     `vault_relpath_to_abs` (lines 31–43). Call site at line 288 changed from
     `vault_relpath_to_abs(cell)` to `current_resolver(cell)`. No other changes.
   - `git diff HEAD -- lua/config/commands.lua` and
     `git diff HEAD -- lua/utils/obsidian_cli/init.lua` both empty.
   - Suite: 92 cases (up from 79), 0 fails. PATH-restricted run also 0 fails.

3. Carry-forward:
   - **Parser-coverage advance:** 5 of 6 → 6 of 6. The parser-coverage
     acceptance criterion on parent #13 is now fully satisfied.
   - **Bookmark-parser flag transition:** open → **closed** (see parent outward
     pass below). Option B (DI resolver seam) was selected; testing strategy was
     pre-documented in the sub-issue; production code changed as fix-with-test
     per the flag's mandate.
   - **Constraint #3 qualification:** parent constraint #3 said "the
     shell-adapter setter is the seam." After this slice two setter-based seams
     exist:
     - `shell.set_runner(fn)` / `shell.reset_runner()` — wraps
       `vim.fn.systemlist`.
     - `parsers.set_resolver(fn)` / `parsers.reset_resolver()` — wraps
       `vault_relpath_to_abs` (`vim.loop.fs_stat` / `fs_realpath`).
     Both are module-level, default to the real implementation on load, neither
     monkey-patches globals or reaches into private functions. The constraint's
     spirit holds; its letter is amended to "the seams."
   - **Deepening candidate (deferred):** `vault_relpath_to_abs` is duplicated
     between `init.lua` (line 33) and `parsers.lua` (lines 7–29). Consolidating
     both into a fifth sibling `vault.lua` would eliminate duplication and make
     the resolver seam reusable for `init.lua`'s bookmark-keymap callsite.
     Out of scope for this cycle; recorded here for the next cycle's pitch.
   - **No new flags raised.** `extract_bookmark_note_path` is well-bounded by
     its documented contract with the seam in place.
