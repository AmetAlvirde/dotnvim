# AAR — Sub-issue #19: backlinks_json parser + command.backlinks_counts builder

1. Did it go as planned? Yes — went exactly as planned.
   All 25 new test cases pass (3 command-builder + 22 parser). Suite exits 0
   with `PATH=/usr/bin:/bin:/opt/homebrew/bin`. No production code changes
   needed; no defects found in the existing implementation.

2. What changed from the sub-issue plan:
   - The sub-issue listed "at least seventeen new `parsers.backlinks_json`
     cases"; 22 were written. The expansion came from splitting the three
     flag-required `{}` shapes into individual named cases (`[]`, `{}`,
     `{"backlinks": []}`) and splitting the three top-level scalar shapes
     (number, string, boolean) into individual named cases. This matches the
     spirit of "each distinct case named directly so a regression is
     identifiable" and is consistent with the acceptance criteria.
   - No other deviations. The fixture (`backlinks_json.txt`) is a `backlinks`
     nested-list with three objects — canonical path + count, `file` +
     `linkCount` aliases, and a missing-count row. End-to-end fixture case
     asserts 3 rows in input order.

3. Carry-forward:
   - Parser-coverage advance: 4 of 6 → 5 of 6. One parser remains:
     `extract_bookmark_note_path`.
   - Backlinks-parser flag (parent `issue.md`): pure-parser sub-requirements
     (nil-on-parse-failure, {}-on-parsed-empty) are both closed by this
     slice. The integration-path sub-requirement — covering the two distinct
     user-facing messages in `init.lua` ("Could not parse backlinks JSON…"
     vs "No backlinks parsed from JSON…") — remains open. It requires the
     shell-adapter seam plus quickfix / scratch-buffer state assertions, or a
     child-Neovim spec. The flag stays open; the parent issue is updated to
     reflect the narrowed residual scope.
   - No new flags introduced. The `vim.tbl_islist is deprecated` warning in
     test output is pre-existing (the implementation uses it; emitted by
     Neovim's deprecation layer). No action required in this slice.
