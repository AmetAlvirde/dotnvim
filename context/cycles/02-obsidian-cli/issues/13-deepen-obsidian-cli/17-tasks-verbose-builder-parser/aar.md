# AAR — tasks_verbose builder + parser (sub-issue #17)

1. Did it go as planned? Yes — straight execution. All 13 proposed tests
   written and green on first run (41 total cases, 0 fails).

2. What changed from the sub-issue plan:

   - None. Nine `parsers.tasks_verbose` cases and four `command.tasks` cases
     were added exactly as specified. The fixture
     (`tests/utils/obsidian_cli/fixtures/tasks_verbose.txt`) is five lines of
     parseable content across two header sections, one inline `path:line:text`
     line, blank lines, and one header-shaped line with a `:digits` suffix —
     matching the acceptance-criteria shape verbatim.
   - No defects found in `parsers.tasks_verbose` or `command.tasks`; no
     fix-with-test was required.
   - `task_item` helper added locally in `parsers_spec.lua` (above the new
     cases) to carry `user_data.obsidian_task_ref` without repeating the shape
     in each assertion. This is a spec-internal detail; production code
     untouched.

3. Carry-forward:

   - Parser-coverage advance: **2/6 → 3/6** (`search_context` [#15], `paths`
     [#16], `tasks_verbose` [this slice]). Three parsers remain:
     `unresolved_verbose`, `backlinks_json`, `extract_bookmark_note_path`.
   - **Outward pass (closure):** Parent `issue.md` parser progress line
     (lines 29–31) was updated to "Progress as of #17: 3 of 6" and now lists
     `tasks_verbose` [#17] — per `sdp-close` for an active artifact. (The
     pre-activation note in the sub-issue had deferred this; closure applied
     the stricter doc-current rule.)
   - Both parent flags (backlinks-parser, bookmark-parser) remain active and
     unmodified. Neither was touched.
   - No new flags.

## Closure checks (sdp-close)

- `./tests/run` and `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exit 0;
  41 cases, 0 fails.
- Sub-issue acceptance criteria marked complete in `sub-issue.md`; unit marked
  **closed** with pointer to this AAR.
- Parent `issue.md` parser progress updated (active artifact).
- No ADR changes (none qualifying).
- `context/ubiquitous-language.md`: no new terms required for this slice.
