# AAR — unresolved_verbose builder + parser (sub-issue #18)

1. Did it go as planned? Yes — incremental TDD (one new test per step). All ten
   proposed surface-level tests were added in order; `./tests/run` stayed green
   after each step (51 total cases, 0 fails).

2. What changed from the sub-issue plan:

   - None. One `command.unresolved` case and nine `parsers.unresolved_verbose`
     cases match the proposed list; fixture
     `tests/utils/obsidian_cli/fixtures/unresolved_verbose.txt` is a hand-curated
     mixed sample (single-source TSV, comma-separated sources, no-`.md` sources,
     `<3`-tab line, blank line, non-numeric count) as specified.
   - No defects in `parsers.unresolved_verbose` or `command.unresolved`; no
     fix-with-test in `lua/utils/obsidian_cli/`.
   - `PATH=/usr/bin:/bin ./tests/run` fails here with `nvim: not found` (nvim is
     under `/opt/homebrew/bin`). Green verification uses
     `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run`, matching sub-issue and
     #17 posture — obsidian remains absent from `$PATH`.

3. Carry-forward:

   - Parser-coverage advance: **3/6 → 4/6** (`search_context` [#15], `paths`
     [#16], `tasks_verbose` [#17], `unresolved_verbose` [this slice]). Two
     parsers remain: `backlinks_json`, `extract_bookmark_note_path`.
   - **Outward pass (closure):** Parent `issue.md` parser progress line updated
     to "Progress as of #18: 4 of 6" and lists `unresolved_verbose` [#18].
   - Parent flags (backlinks-parser, bookmark-parser) unchanged.
   - No new flags. Mutation test not recorded (optional per sub-issue; #15
     already satisfied parent mutation criterion).

## Closure checks (sdp-close)

- `./tests/run` and `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exit 0;
  51 cases, 0 fails.
- Sub-issue acceptance criteria marked complete in `sub-issue.md`.
- Parent `issue.md` parser progress updated (active artifact).
- No ADR changes.
- `context/ubiquitous-language.md`: no new terms required for this slice.
