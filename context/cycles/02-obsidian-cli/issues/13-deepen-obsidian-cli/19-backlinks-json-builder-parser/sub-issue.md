# Sub-issue — backlinks_json parser + command.backlinks_counts builder

GitHub issue: #19 (folder slug per ADR-0002 — confirm at activation; rename if
the actual issue gets a different number). Sixth sub-issue of parent #13. The
fifth parser-pass slice after #15 (`search_context`), #16 (`paths`), #17
(`tasks_verbose`), and #18 (`unresolved_verbose`). Lands the unit tests for
`parsers.backlinks_json` (the schema-tolerant JSON decoder for
`obsidian backlinks ... format=json`) and the `command.backlinks_counts(rel)`
shell-escaped command-builder leaf. Picked from the parent issue's sequencing
list (`issue.md` line 111: "`try_decode_json_object` + `backlinks_json_to_rows`
— backlinks JSON, schema-tolerant") — first parser-pass item still open after
#18 closed `unresolved_verbose`.

Engages the **backlinks-parser flag** (`#14 AAR → backlinks-parser sub-issue`)
on the parent's open-flag list. The flag is **partially resolved** by this
slice: pure-parser coverage of `nil`-on-parse-failure and `{}`-on-parsed-empty
lands here. The `init.lua` user-facing branch coverage ("Could not parse
backlinks JSON…" vs "No backlinks parsed from JSON…") stays out of scope —
those branches require the shell seam plus quickfix/scratch state, and are
deferred to a later integration / presenter slice. The flag stays **open**
after this slice closes, with a follow-up note recording which sub-leaves of
its requirement remain. The bookmark-parser flag
(`#14 AAR → bookmark-parser sub-issue`) remains active and unmodified; this
slice does not touch `parsers.extract_bookmark_note_path`.

## Description

Add unit tests for two leaf modules already in place from #14:

- `command.backlinks_counts(rel)` — builds the string
  `"obsidian backlinks path=<shellescape(rel)> counts format=json"`. Mirrors
  the shell-escape posture established by `command.search_context(query)` in
  #15, and the path-shellescape posture used by `command.history_list`,
  `command.history_read`, `command.diff`, and `command.outline` (none of which
  have dedicated builder specs yet). The `counts format=json` token-pair is
  **load-bearing** — the parser depends on JSON output. Future restructuring
  that drops `format=json` (or swaps it for a different format flag) would
  break the parser silently; the builder spec is the regression guard.

- `parsers.backlinks_json(text)` — exercise the schema-tolerant JSON decoder.
  The parser has a deliberate, documented contract that the closing AAR of
  #14 explicitly preserved (`14-layer-skeleton-tracer/aar.md` lines 17–23):

  - **`nil`** is returned on JSON parse failure (non-JSON input,
    unparseable input, empty/whitespace-only input).
  - **An empty table `{}`** is returned on parse success that yields no
    backlink rows (valid JSON document with the wrong shape, an empty list,
    or a structure the schema-tolerant matchers cannot extract paths from).
  - **A non-empty list of `{ path = string, count = integer }`** is returned
    on parse success that yields rows.

  The two-outcome distinction (`nil` vs `{}`) is the contract that
  `init.lua`'s `M.backlinks_counts_to_quickfix` branches on
  (`init.lua:228` "Could not parse…" vs `init.lua:233` "No backlinks
  parsed…"). Pure-parser tests verify the contract; integration tests verify
  the message routing.

  Beyond the two-outcome contract, the parser exposes several
  schema-tolerant behaviors:

  1. **Empty / whitespace-only input** → `nil` (treated as parse failure).
  2. **Non-JSON garbage input** → `nil`.
  3. **Substring retry** — when initial `vim.json.decode` fails, the parser
     retries from the first `{` or `[`. Lines like
     `"warning: foo\n{\"a.md\": 3}"` should still parse.
  4. **List of strings** — `["a.md", "b.md"]` → two rows, each with
     `count = 1`.
  5. **List of objects** — `[{path: "a.md", count: 4}]` → one row.
  6. **Object-key shape** — `{"a.md": 3, "b.md": 1}` → two rows. (The keys
     contain `.md`, the values are numbers.)
  7. **Nested-list shape** — `{"backlinks": [...]}`,
     `{"links": [...]}`, `{"items": [...]}`, `{"results": [...]}`,
     `{"files": [...]}` — first non-empty list wins.
  8. **Field aliases on objects** — `path | file | filePath | filepath |
     source | from | name` for the path; `count | linkCount | links |
     total | n` for the count.
  9. **Count fallback** — when count is missing, non-numeric, or `< 1`,
     it defaults to `1` (the documented row-emission posture). The row is
     **not** dropped on bad-count.
  10. **Empty / missing path** → row dropped silently. The `add(path, count)`
      helper trims and discards rows whose path is empty.
  11. **Top-level scalar / non-table JSON** (e.g. `"42"`, `"true"`, `"\"a\""`) →
      decode succeeds, but `data` is not a table → returns `{}` (not `nil`).
      Documents the parse-success-but-no-rows path on a non-conventional shape.

No production code changes are required. Both `command.backlinks_counts` and
`parsers.backlinks_json` already exist from #14; this slice adds their tests
and one fixture file (`backlinks_json.txt`). If the tests reveal a defect in
the existing implementation, fix-with-test stays in scope; speculative parser
or builder changes do not.

## Dependency classification

| Dependency                                       | Category                 | Testing strategy                                                                                                                                  |
| ------------------------------------------------ | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `obsidian` CLI binary                            | True external (platform) | Not invoked. Specs read fixture text from disk; the command builder returns a string and never executes it.                                       |
| `vim.fn.shellescape`                             | In-process (Neovim API)  | Exercised through the public `command.backlinks_counts` surface. No stub. Mirror posture from `command.search_context` cases (#15).               |
| `vim.fn.systemlist`                              | In-process (Neovim API)  | Not exercised. Shell seam stays untouched.                                                                                                        |
| `vim.json.decode`                                | In-process (Neovim API)  | Used by `parsers.backlinks_json` against fixture-derived inputs. No stub. Built-in availability assumed (cycle 01 / #14 already rely on it).      |
| `vim.trim`, `vim.tbl_islist`                     | In-process (Neovim API)  | Used by `parsers.backlinks_json`. No stub.                                                                                                        |
| Lua patterns (`string.find`, `string.match`)     | In-process               | Used for substring retry and key-shape detection. Tested via observable parser output.                                                            |
| `lua/config/vaults.lua` (`VAULT_ROOTS`)          | In-process               | Loaded transitively when `parsers.lua` is required. No test substitution — same posture as #14 / #15 / #16 / #17 / #18.                            |
| `mini.test`                                      | In-process               | Loaded via cycle 01's harness. Spec runs through `./tests/run`.                                                                                    |
| Captured CLI fixture (`backlinks_json.txt`)      | Test artifact            | Plain text under `tests/utils/obsidian_cli/fixtures/`, read by the spec via `io.open`. Documented as captured-by-hand in the AAR.                  |

No new seams introduced. The shell-adapter seam from #14 is **not** exercised
— both modules under test are pure with respect to shell execution. The
spec passes `text` strings (or fixture-loaded content) directly to
`parsers.backlinks_json` rather than reading via `shell.run`.

## Interface design / scope

The interfaces under test are already finalized in #14. This slice's
"interface design" is the **test surface** — what the spec asserts and what
it does not.

### `command.backlinks_counts` test surface

The spec requires the public `command` module and calls
`command.backlinks_counts(rel)` directly. No reaching into locals; the private
`shellescape` alias is not referenced (mirrors the #15 posture for
`command.search_context`).

The new cases extend the existing `tests/utils/obsidian_cli/command_spec.lua`
file (created in #15, extended in #16, #17, #18). They sit alongside the five
`search_context` cases, the two `command.orphans` / `command.deadends`
cases, the four `command.tasks` cases, and the one `command.unresolved` case
already there.

Assertions cover:

1. **Plain vault-relative path.** Input `"notes/topic.md"` produces
   `"obsidian backlinks path=" .. vim.fn.shellescape("notes/topic.md") ..
   " counts format=json"`. Verifies the literal command shape and that the
   `counts format=json` token-pair appears verbatim. Built dynamically using
   `vim.fn.shellescape` to avoid hard-coding shell-quoted output (mirror #15
   posture).
2. **Path with whitespace.** Input `"folder with spaces/note.md"` produces
   the corresponding shellescape'd output. Confirms shell-escape is applied
   to the path argument (the parent issue's command-builder shell-escape
   criterion is already closed by #15; this is reinforcement, not closure).
3. **Path with single quotes.** Input `"it's complicated.md"` produces a
   correctly shell-escaped form. Mirrors the #15 single-quote case for
   `search_context query=...`.

### `parsers.backlinks_json` test surface

Spec requires `utils.obsidian_cli.parsers` and calls
`parsers.backlinks_json(text)` against fixture-derived or inline-string
inputs. The new cases extend the existing
`tests/utils/obsidian_cli/parsers_spec.lua` file.

The two flag-required cases — **the parent flag's load-bearing requirement** —
are #1 and #2 below. Both must be present, separately named, and
asserted as separate values (`nil` vs `{}`):

1. **Non-JSON input yields `nil`.** Input `"not json at all"` (or
   `"warning without payload"`, or any string with no `{` / `[` and no
   parseable JSON content). Asserts `parsers.backlinks_json(...) == nil`.
   This is the "parse-failure" branch of the contract.
2. **Valid JSON with no extractable rows yields `{}` (empty table).**
   Input `"[]"` (an empty array). Asserts the return value is a table and
   that `#result == 0`. Other shapes that should also produce `{}`:
   `"{}"` (empty object — the per-key loop finds nothing extractable),
   `'{"backlinks": []}'` (named-list shape with empty list — falls through
   the nested matcher and the per-key loop both yield nothing). Each of
   these is its own distinct case so a regression in one shape is named
   directly.

Beyond the flag-required cases, the spec covers the schema-tolerant matrix:

3. **Empty / whitespace-only / `nil` input → `nil`.** Inputs `""`, `"   "`,
   `nil`. All three yield `nil`. Documents the trim-and-empty-check on entry.
4. **Substring retry (preamble before JSON).** Input
   `'warning: stale cache\n{"a.md": 3}'` → one row
   `{ path = "a.md", count = 3 }`. Verifies the `text:find("[%[%{]")`
   fallback path.
5. **Substring retry that still fails → `nil`.** Input `'noise {bad json'`
   → `nil`. The fallback decode also raises; the parser returns `nil`.
6. **Top-level list of strings.** Input `'["notes/a.md", "notes/b.md"]'` →
   two rows, each with `count = 1`. String-item branch in `from_item`.
7. **Top-level list of objects, `path` + `count` fields.** Input
   `'[{"path": "notes/a.md", "count": 4}, {"path": "notes/b.md", "count": 2}]'`
   → two rows in input order with the named fields applied.
8. **Field-alias coverage.** One case per non-default alias is excessive;
   one consolidated case verifying the parser accepts at least one
   alternative path-field name (e.g. `file` instead of `path`) and at least
   one alternative count-field name (e.g. `linkCount` instead of `count`)
   suffices. Input
   `'[{"file": "notes/a.md", "linkCount": 7}]'` → one row
   `{ path = "notes/a.md", count = 7 }`.
9. **Count fallback when missing.** Input
   `'[{"path": "notes/a.md"}]'` → one row with `count = 1`. Documents the
   default-to-`1` posture.
10. **Count fallback when zero or negative.** Input
    `'[{"path": "notes/a.md", "count": 0}]'` →
    `count = 1` (the `< 1` clamp). Input
    `'[{"path": "notes/a.md", "count": -3}]'` →
    `count = 1`. The row is **not** dropped.
11. **Empty path drops the row.** Input
    `'[{"path": "", "count": 5}, {"path": "notes/a.md", "count": 2}]'`
    → one row (the second). Documents the empty-path filter in `add`.
12. **Whitespace-only path drops the row.** Input
    `'[{"path": "   ", "count": 5}]'` → `{}`. Trim-then-empty-check.
13. **Object-key shape (`.md` keys with numeric values).** Input
    `'{"notes/a.md": 3, "notes/b.md": 1}'` → two rows with the keys as
    paths. Iteration order is not asserted (Lua `pairs` order is
    implementation-defined); the spec asserts the multiset
    (sort-and-compare) instead.
14. **Nested-list shape — `backlinks` key.** Input
    `'{"backlinks": [{"path": "notes/a.md", "count": 2}]}'` → one row.
15. **Nested-list shape — `items` key (alternative name).** Input
    `'{"items": [{"path": "notes/a.md", "count": 5}]}'` → one row.
    Documents the alias coverage on the nested-list matcher.
16. **Top-level scalar JSON yields `{}`.** Input `'42'`, `'"hello"'`, `'true'`.
    Decode succeeds, `data` is not a table → returns `{}` (not `nil`).
    Documents the "parse-success-but-data-not-table" path.
17. **Mixed-shape fixture.** A JSON document combining: a nested-list
    `backlinks` array with multiple objects (using mixed field aliases),
    and at least one row with a missing count (relying on the fallback).
    Loaded from
    `tests/utils/obsidian_cli/fixtures/backlinks_json.txt` and parsed
    end-to-end. Expected row count and per-row values verified.

The fixture lives at
`tests/utils/obsidian_cli/fixtures/backlinks_json.txt` and is read at
spec time. Unlike the `unresolved_verbose.txt` fixture (split by `\n`
into a `lines` array), this fixture is read as a **single string** via
`io.open`+`read("*a")` and passed to `parsers.backlinks_json` whole. The
fixture is a representative hand-curated sample modeled after what
`obsidian backlinks path=… counts format=json` plausibly emits — same
captured-by-hand posture as #15 / #16 / #17 / #18.

### Mutation-test recording

Not required by the parent — #15 already closed the "at least one parser has
a mutation test" criterion. Optional during implementation if the tester
wants to confirm the spec catches regressions. Suggested mutations (none
committed):

- In `parsers.backlinks_json`, change `if not ok or data == nil then
  return nil end` (final substring-retry guard, line 195) to `return rows`
  (an empty table). Case 1 (non-JSON input) turns red — it expects `nil`,
  receives `{}`. Documents the load-bearing parse-failure branch.
- Change `if not count or count < 1 then count = 1 end` to remove the
  clamp. Case 10 (count = 0) turns red — it expects `count = 1`, receives
  `count = 0`.

## Acceptance criteria

- [ ] `tests/utils/obsidian_cli/command_spec.lua` is extended with three
      new cases asserting `command.backlinks_counts(rel)` returns the
      shell-escaped form for: plain path, path with whitespace, path with
      single quotes. The literal `counts format=json` token-pair appears in
      every assertion. Existing `search_context`, `command.orphans` /
      `command.deadends`, `command.tasks`, and `command.unresolved` cases
      remain unchanged and green.
- [ ] `tests/utils/obsidian_cli/parsers_spec.lua` is extended with the
      flag-required two cases for `parsers.backlinks_json`:
      (a) non-JSON input → `nil`,
      (b) valid JSON with no extractable rows → `{}` (empty table).
      Each is named explicitly in the test title so a regression in one
      branch is identifiable directly. Both cases are present.
- [ ] `tests/utils/obsidian_cli/parsers_spec.lua` is further extended with
      cases for: empty / whitespace / `nil` input → `nil`; substring retry
      success; substring retry failure → `nil`; list-of-strings shape;
      list-of-objects shape with `path` + `count`; field-alias coverage;
      count fallback (missing); count fallback (zero / negative); empty
      path dropped; whitespace path dropped; object-key shape; nested-list
      shapes (`backlinks`, `items`); top-level scalar JSON → `{}`; mixed-shape
      fixture-driven case. The existing `search_context`, `paths`,
      `tasks_verbose`, and `unresolved_verbose` cases remain unchanged and
      green.
- [ ] `tests/utils/obsidian_cli/fixtures/backlinks_json.txt` exists,
      contains a hand-curated mixed-shape JSON sample (nested `backlinks`
      list with multiple objects, mixed field aliases, at least one
      missing-count row), and is read by the mixed-input
      `parsers.backlinks_json` spec at runtime. Read as a single string
      (not split by `\n`).
- [ ] `./tests/run` exits 0 on the whole suite — the new cases plus
      everything from #14, #15, #16, #17, #18, plus cycle 01's
      `wordcount_spec.lua`.
- [ ] `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exits 0. No shell
      call to `obsidian` happens during the new specs. (Carry-forward
      posture from #14 / #15 / #16 / #17 / #18.)
- [ ] No reaching into local functions or monkey-patching globals in the
      new cases. `parsers.backlinks_json` and `command.backlinks_counts`
      are exercised through their public module surface only.
- [ ] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is empty
      (carry-forward from parent — this slice does not edit the consumer).
- [ ] `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` shows no
      changes other than fixes-with-test (if any). Speculative parser or
      builder changes are out of scope.

## Proposed tests

| Title                                                                                                          | What it verifies                                                                                                                                              |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `command.backlinks_counts(rel)` shell-escapes a plain vault-relative path                                      | Output equals `"obsidian backlinks path=" .. vim.fn.shellescape(rel) .. " counts format=json"`. Token-pair `counts format=json` is verbatim.                  |
| `command.backlinks_counts(rel)` shell-escapes a path with whitespace                                           | Whitespace-bearing path is wrapped/escaped via `vim.fn.shellescape`. Reinforces the parent's shell-escape criterion (already closed by #15).                  |
| `command.backlinks_counts(rel)` shell-escapes a path with single quotes                                        | Single-quote-bearing path is correctly escaped. Mirrors the #15 single-quote case for `search_context`.                                                       |
| `parsers.backlinks_json` returns `nil` on non-JSON input **(parent flag, load-bearing)**                       | `parsers.backlinks_json("not json")` → `nil`. The parse-failure branch of the contract.                                                                       |
| `parsers.backlinks_json` returns `{}` on valid JSON with no rows **(parent flag, load-bearing)**               | `parsers.backlinks_json("[]")` and `parsers.backlinks_json("{}")` and `'{"backlinks": []}'` each return a table with `#result == 0` (and not `nil`).          |
| `parsers.backlinks_json` returns `nil` on empty / whitespace / `nil` input                                      | `""`, `"   "`, `nil` each yield `nil`. Trim-and-empty-check on entry.                                                                                          |
| `parsers.backlinks_json` succeeds via substring retry when JSON is preceded by noise                            | `'warning: stale\n{"a.md": 3}'` → one row `{ path = "a.md", count = 3 }`.                                                                                      |
| `parsers.backlinks_json` returns `nil` when both decode and substring retry fail                                | `'noise {bad json'` → `nil`.                                                                                                                                   |
| `parsers.backlinks_json` parses a top-level list of strings as paths with `count = 1`                          | `'["a.md", "b.md"]'` → two rows, each `count = 1`.                                                                                                              |
| `parsers.backlinks_json` parses a top-level list of objects with `path` and `count`                            | `'[{"path": "a.md", "count": 4}, {"path": "b.md", "count": 2}]'` → two rows in input order.                                                                    |
| `parsers.backlinks_json` accepts field aliases for path and count                                               | `'[{"file": "a.md", "linkCount": 7}]'` → one row `{ path = "a.md", count = 7 }`.                                                                                |
| `parsers.backlinks_json` falls back to `count = 1` when count is missing                                        | `'[{"path": "a.md"}]'` → `count = 1`.                                                                                                                          |
| `parsers.backlinks_json` clamps zero or negative count to 1                                                     | `'[{"path": "a.md", "count": 0}]'` and `'[{"path": "a.md", "count": -3}]'` each yield `count = 1`. Row not dropped.                                            |
| `parsers.backlinks_json` drops rows with empty path                                                              | `'[{"path": "", "count": 5}, {"path": "a.md", "count": 2}]'` → one row (the second).                                                                            |
| `parsers.backlinks_json` drops rows with whitespace-only path                                                    | `'[{"path": "   ", "count": 5}]'` → `{}`.                                                                                                                       |
| `parsers.backlinks_json` parses object-key shape (`.md` keys with numeric values)                                | `'{"notes/a.md": 3, "notes/b.md": 1}'` → two rows; multiset asserted (Lua `pairs` order not guaranteed).                                                        |
| `parsers.backlinks_json` parses nested-list shape under `backlinks`                                              | `'{"backlinks": [{"path": "a.md", "count": 2}]}'` → one row.                                                                                                    |
| `parsers.backlinks_json` parses nested-list shape under `items`                                                  | `'{"items": [{"path": "a.md", "count": 5}]}'` → one row. Alias coverage on the nested matcher.                                                                  |
| `parsers.backlinks_json` returns `{}` for top-level scalar JSON                                                  | `'42'`, `'"hello"'`, `'true'` decode successfully but `data` is not a table → `{}` (not `nil`).                                                                 |
| `parsers.backlinks_json` against a mixed-shape fixture                                                           | End-to-end count and value check from `tests/utils/obsidian_cli/fixtures/backlinks_json.txt`.                                                                  |

A deliberate-failure / mutation verification is **not required** by this
slice. Optional and unrecorded.

## Affected artifacts

- Modified: `tests/utils/obsidian_cli/command_spec.lua` — extended with
  three new `command.backlinks_counts` cases.
- Modified: `tests/utils/obsidian_cli/parsers_spec.lua` — extended with at
  least seventeen new `parsers.backlinks_json` cases (two flag-required +
  fifteen schema-tolerant matrix cases including the fixture-driven case).
- New: `tests/utils/obsidian_cli/fixtures/backlinks_json.txt` — read as a
  single string.
- Unchanged (verified by `git diff`): everything under
  `lua/utils/obsidian_cli/`, `lua/config/commands.lua`,
  `tests/utils/obsidian_cli/init_spec.lua`,
  `tests/utils/obsidian_cli/fixtures/search_context.txt`,
  `tests/utils/obsidian_cli/fixtures/paths.txt`,
  `tests/utils/obsidian_cli/fixtures/tasks_verbose.txt`,
  `tests/utils/obsidian_cli/fixtures/unresolved_verbose.txt`,
  `tests/init.lua`, `tests/run`, `tests/utils/wordcount_spec.lua`.
- Unchanged: closed sibling sub-issue folders (`14-...`, `15-...`,
  `16-...`, `17-...`, `18-...`) — this slice does not edit them.
- **Updated at closure:** parent `issue.md` parser progress line (5 of 6,
  lists `backlinks_json` [#19]) — per `sdp-close` outward pass for an
  active artifact; the slice still closes no parent acceptance criterion
  outright. The backlinks-parser flag's pure-parser sub-requirement is
  resolved at closure; the integration-path sub-requirement remains.
- New (closing artifact): `19-backlinks-json-builder-parser/aar.md` —
  records any deviations from this plan, the parser-coverage advance
  (4 of 6 → 5 of 6), and the precise residual scope of the backlinks-parser
  flag after this slice.

## Dependencies

- **Sub-issue #14 (closed).** Provides `command.backlinks_counts`,
  `parsers.backlinks_json`, the `tests/utils/obsidian_cli/` directory,
  the layered module shape this slice tests against, and (critically)
  the `nil` vs `{}` two-outcome contract that this slice's flag-required
  cases preserve. See `14-layer-skeleton-tracer/aar.md` lines 17–23 for
  the contract origin.
- **Sub-issue #15 (closed).** Established
  `tests/utils/obsidian_cli/command_spec.lua` and
  `tests/utils/obsidian_cli/parsers_spec.lua`, the
  `fixtures/search_context.txt` posture, and the shellescape-via-public-API
  pattern this slice replicates for `command.backlinks_counts`.
- **Sub-issue #16 (closed).** Confirmed the static / argument-bearing
  builder spec pattern in `command_spec.lua`. Reused for
  `command.backlinks_counts` (which takes a `rel` argument and shell-escapes
  it — closer in shape to #15's `command.search_context` than to #16's
  static builders, but the file-extension pattern is identical).
- **Sub-issue #17 (closed).** Confirmed the parser-coverage outward-pass
  posture (update parent `issue.md` parser progress line at closure).
- **Sub-issue #18 (closed).** Most recent precedent. This slice mirrors
  #18's structure end-to-end: extend two existing spec files, add one
  fixture, no production-code edits expected, partial advance on the
  parser-coverage parent criterion.
- **ADR-0001** — `mini.test` runner. Accepted.
- **ADR-0002** — folder slug `19-...` tracks GitHub issue number.
  Confirm `#19` at activation; rename folder if the actual issue gets a
  different number.
- No dependency on any other parent or any other cycle.

## Out of scope (deferred to later sub-issues)

- **Integration / shell-seam coverage of `M.backlinks_counts_to_quickfix`
  in `init.lua`.** The leaf calls `shell.run`, joins lines into `text`,
  passes the joined string to `parsers.backlinks_json`, and branches on
  the parser's return value across **three** distinct user-facing message
  shapes:
  - `init.lua:228` — `"Could not parse backlinks JSON. Opened raw CLI output."`
    (parser returned `nil`).
  - `init.lua:233` — `"No backlinks parsed from JSON. Opened raw CLI output."`
    (parser returned `{}`).
  - The success branch — `setqflist` of the rows, `"Loaded N backlink(s)…"`
    or equivalent message.
  Each branch needs the shell-adapter seam plus quickfix / scratch-buffer
  state assertions, or a child-Neovim spec. Defer to a presenter-testability
  slice. **The backlinks-parser flag is therefore only partially resolved
  by this slice.** The pure-parser sub-requirement (`nil` vs `{}` distinction)
  is closed; the integration-routing sub-requirement remains, and the flag
  stays open with an updated note pointing at the deferral.
- Parser tests for `extract_bookmark_note_path`. **Bookmark-parser flag
  remains active and unmodified**; pre-document step is still required
  before that slice activates.
- Command-builder tests for the remaining builders (`history_list`,
  `history_read`, `diff`, `outline`, `wordcount`, `bookmarks_verbose`,
  `bookmark_add`, `task_toggle`). The parent's command-builder shell-escape
  criterion is already closed by #15. Future per-leaf builder specs are
  nice-to-have, not required.
- Any ADR-0003 work. Reserved for the final sub-issue.
- Any edits to `lua/utils/obsidian_cli/` modules unless the new specs reveal
  a defect (fix-with-test only).
- Property-based or generative testing of the schema-tolerant matrix.
  Hand-curated cases per branch are sufficient and consistent with the
  preceding parser-pass slices.

## Pre-activation review (parent linkage)

### Parent acceptance criteria this slice closes outright

None. The remaining open parser criterion ("every parser has a unit test")
is multi-shot — only fully closed once all six parsers have specs. The
other open parent criteria (`init.lua`-export parity, layered sibling
presence, single shell-call grep, `set_runner` / `reset_runner` exposure,
`commands.lua` diff empty, ADR-0003 decision) sit outside this slice's
scope.

### Parent acceptance criteria this slice partially advances

- "Every output parser introduced or extracted by the deepening has at
  least one passing unit test under `tests/utils/obsidian_cli/`,
  exercised by `./tests/run`." — **5 of 6 parsers covered** after
  closure (`search_context` from #15 + `paths` from #16 + `tasks_verbose`
  from #17 + `unresolved_verbose` from #18 + `backlinks_json` from this
  slice). One remains: `extract_bookmark_note_path`.

### Parent acceptance criteria this slice maintains (does not regress)

- `./tests/run` exits 0 on the whole suite.
- `PATH=...` test suite green with `obsidian` absent.
- `git diff` against `lua/config/commands.lua` empty.
- No reaching into local functions or monkey-patching internals.

### Parent flags this slice resolves or updates

- **Backlinks-parser flag (`#14 AAR → backlinks-parser sub-issue`):**
  **partially resolved.** The flag's two pure-parser sub-requirements
  — exercise the `nil`-on-parse-failure branch, exercise the
  `{}`-on-parsed-empty branch — are both closed by this slice's
  flag-required cases. The flag's integration-path sub-requirement
  (covering the two distinct user-facing messages
  `"Could not parse..."` vs `"No backlinks parsed..."`) is **not**
  closed; pure-parser tests cannot reach the message-routing seam.
  **The flag stays open after this slice closes,** with the AAR
  recording the precise residual scope and pointing at a future
  presenter / shell-seam slice.
- **Bookmark-parser flag (`#14 AAR → bookmark-parser sub-issue`):**
  unchanged. Stays active and the pre-document step is still required
  for that slice.

### Outward pass — parent issue updates after closure

On closure, update parent `issue.md`:

1. Parser progress line (lines 29–32) to "Progress as of #19: 5 of 6"
   and add `backlinks_json` [#19] to the covered list — per `sdp-close`
   for an active artifact, mirroring #17's and #18's outward pass.
2. Backlinks-parser flag entry (lines 155–168): annotate that the
   pure-parser sub-requirement is resolved by #19, and that the
   remaining open scope is the integration-path coverage of the two
   user-facing messages in `init.lua`. Either rewrite the flag body in
   place to reflect the narrowed scope, or leave the flag as-is and add
   a closing pointer to `19-...aar.md`. The exact form is the closer's
   call (per `sdp-close`).

This slice's AAR also records:

- Parser-coverage advance: `4/6 → 5/6` (redundant with parent text; AAR
  is the audit trail).
- Backlinks-parser flag status transition: pure-parser sub-requirement
  closed; integration sub-requirement remains.
- Any deviations from the proposed test list, with rationale.
- Any defects-fixed-with-test in `parsers.backlinks_json` or
  `command.backlinks_counts` (none expected).
- Any new flag if the implementation surfaces an unresolvable nuance.
  Likely candidates worth recording (only if observed): JSON shapes
  emitted by the real `obsidian` CLI that the schema-tolerant matchers
  do not cover (would suggest a follow-up to widen the alias list);
  edge cases in `vim.tbl_islist` behavior on Lua 5.1 vs LuaJIT (the
  current parser uses it once); rows whose `count` is a string-encoded
  number (e.g. `"3"`) — `tonumber` handles this correctly today, but
  it is worth a fixture line to lock in the behavior.

No new flags expected — `parsers.backlinks_json` is well-bounded by its
documented contract. If a nuance surfaces, record it as a flag in this
sub-issue's AAR.

## Suggested GitHub issue title

`feature: parser-pass slice — backlinks_json parser + command.backlinks_counts builder`

Alternative shorter forms:

- `feature: backlinks_json parser specs + command.backlinks_counts builder spec`
- `test: backlinks_json parser (schema-tolerant JSON) + command.backlinks_counts builder`
