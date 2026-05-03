# Sub-issue — unresolved_verbose builder + parser (TSV link/count/sources)

GitHub issue: #18 (folder slug per ADR-0002 — confirm at activation; rename if
the actual issue gets a different number). Fifth sub-issue of parent #13. The
fourth parser-pass slice after #15 (`search_context`), #16 (`paths`), and #17
(`tasks_verbose`). Lands the unit tests for `parsers.unresolved_verbose` (the
tab-separated `<link>\t<count>\t<sources>` format produced by
`obsidian unresolved verbose`) and the trivial static command-builder
`command.unresolved()`. Picked from the parent issue's sequencing list
(`issue.md` line 110: "unresolved-verbose tab-separated parser") — first item
still open after #17 closed `tasks_verbose`.

Engages neither parent flag. The backlinks-parser flag
(`#14 AAR → backlinks-parser sub-issue`) and the bookmark-parser flag
(`#14 AAR → bookmark-parser sub-issue`) remain active and unmodified; this slice
does not touch `parsers.backlinks_json`, `parsers.extract_bookmark_note_path`,
or the `M.backlinks_counts_to_quickfix` integration path.

## Description

Add unit tests for two leaf modules already in place from #14:

- `command.unresolved()` — the second-to-last static command-builder leaf still
  uncovered. No arguments, no shell-escape, no shape variation; returns the
  fixed string `"obsidian unresolved verbose"`. Trivial but a load-bearing
  regression guard: future restructuring of `command.lua` that swaps the string
  (or accidentally drops the `verbose` token, which would change the CLI's
  output shape and break the parser) would be caught.

- `parsers.unresolved_verbose(lines)` — exercise the TSV transformation. Each
  parseable line has the shape `<link>\t<count>\t<sources>`, where `<sources>`
  is a comma-and-space-separated list of `.md` paths. The parser has four
  observable behaviors:
  1. **Three-or-more tab parts** are parsed; fewer-tab lines are silently
     skipped. The `>= 3` guard is intentional and is the only structural
     filter beyond the empty-line skip.
  2. **First-source extraction** picks the first `*.md` token from the sources
     cell using two patterns: `^%s*([^,%s]+%.md)%s*[, ]` (sources with a
     comma- or space-delimited tail) and `^%s*([^,%s]+%.md)%s*$` (single-source
     sources cell). The matched source becomes `filename`; the full original
     `<sources>` string is preserved in the item's `text` field.
  3. **No-`.md`-source fallback** — when neither pattern matches, the item is
     still emitted with `filename = ""` (empty string, not `nil`) and the same
     `text` shape. This is the parser's documented degraded-but-non-dropping
     behavior; downstream `setqflist` accepts an empty filename.
  4. **Item text shape** is always
     `"<link> (count=<count>) sources: <sources>"`. When `count` is not a
     valid number, `tostring(count or "")` renders as the empty string —
     producing literally `"... (count=) sources: ..."`. The parser does not
     drop the line in that case.

Output items carry **no** `user_data` field (unlike `parsers.tasks_verbose`).
Specs assert `lnum = 1` and `col = 1` consistently — the CLI emits one logical
row per unresolved link, no per-occurrence line number is available.

No production code changes are required. Both `command.unresolved` and
`parsers.unresolved_verbose` already exist from #14; this slice adds their
tests and one fixture file (`unresolved_verbose.txt`). If the tests reveal a
defect in the existing implementation, fix-with-test stays in scope;
speculative parser or builder changes do not.

## Dependency classification

| Dependency                                       | Category                 | Testing strategy                                                                                                                |
| ------------------------------------------------ | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| `obsidian` CLI binary                            | True external (platform) | Not invoked. Specs read fixture text from disk; the command builder returns a string and never executes it.                     |
| `vim.fn.shellescape`                             | In-process (Neovim API)  | Not exercised — `command.unresolved` takes no arguments and does not shell-escape.                                              |
| `vim.fn.systemlist`                              | In-process (Neovim API)  | Not exercised. Shell seam stays untouched.                                                                                      |
| `vim.trim`, `vim.split`                          | In-process (Neovim API)  | Used by `parsers.unresolved_verbose` against fixture-derived inputs. No stub.                                                   |
| Lua patterns (`string.match`, `string.format`)   | In-process               | Used for first-source extraction and item-text formatting. Tested via observable parser output.                                 |
| `lua/config/vaults.lua` (`VAULT_ROOTS`)          | In-process               | Loaded transitively when `parsers.lua` is required. No test substitution — same posture as #14 / #15 / #16 / #17.               |
| `mini.test`                                      | In-process               | Loaded via cycle 01's harness. Spec runs through `./tests/run`.                                                                 |
| Captured CLI fixture (`unresolved_verbose.txt`)  | Test artifact            | Plain text under `tests/utils/obsidian_cli/fixtures/`, read by the spec via `io.open`. Documented as captured-by-hand in the AAR. |

No new seams introduced. The shell-adapter seam from #14 is **not** exercised
— both modules under test are pure with respect to shell execution.

## Interface design / scope

The interfaces under test are already finalized in #14. This slice's
"interface design" is the **test surface** — what the spec asserts and what
it does not.

### `command.unresolved` test surface

The spec requires the public `command` module and calls `command.unresolved()`
directly. No reaching into locals; the private `shellescape` alias is not
referenced.

The new case extends the existing `tests/utils/obsidian_cli/command_spec.lua`
file (created in #15, extended in #16 and #17). It sits alongside the five
`search_context` cases, the two `command.orphans` / `command.deadends`
static-builder cases, and the four `command.tasks` cases already there.

Assertions cover:

1. **`command.unresolved()` returns the exact string `"obsidian unresolved verbose"`.**
   Hardcoded comparison — no `shellescape` composition needed, and the `verbose`
   token is load-bearing (the parser depends on the TSV verbose output shape).

### `parsers.unresolved_verbose` test surface

Spec requires `utils.obsidian_cli.parsers` and calls
`parsers.unresolved_verbose(lines)` against fixture-derived inputs. The new
cases extend the existing `tests/utils/obsidian_cli/parsers_spec.lua` file.

Assertions cover:

1. **Single TSV line, single source.** Input
   `"some-link\t3\tnotes/source.md"` produces one item with
   `filename = "notes/source.md"`, `lnum = 1`, `col = 1`, and
   `text = "some-link (count=3) sources: notes/source.md"`. Exercises the
   `^%s*([^,%s]+%.md)%s*$` (single-source) branch.
2. **Single TSV line, comma-separated sources.** Input
   `"link\t2\tnotes/a.md, notes/b.md"` produces one item with
   `filename = "notes/a.md"` (first match) and
   `text = "link (count=2) sources: notes/a.md, notes/b.md"` (full original
   sources string preserved). Exercises the
   `^%s*([^,%s]+%.md)%s*[, ]` (delimited-tail) branch.
3. **Multiple TSV lines.** Two-line input → two items in input order. Confirms
   per-line independence (no shared state between iterations, contrast with
   `parsers.tasks_verbose`).
4. **Sources cell with no `.md` token.** Input
   `"orphan-link\t1\tunknown"` produces one item with `filename = ""`
   (empty string, not `nil` — the documented degraded fallback) and
   `text = "orphan-link (count=1) sources: unknown"`. Documents the parser's
   non-dropping posture for malformed sources.
5. **Skips lines with fewer than three tab parts.** Inputs `"only-one-cell"`,
   `"two\tcells"`, `""`, and `"   "` all yield no items. Verifies both the
   `>= 3` structural guard and the empty-line skip.
6. **Skips empty and whitespace-only lines.** A `nil` input field, an empty
   string, and a whitespace-only string each yield no items. Mixed with valid
   TSV lines, the valid ones still appear in input order.
7. **Non-numeric count renders as empty string in text.** Input
   `"weird-link\tnotanum\tnotes/x.md"` produces one item where `text` contains
   `"(count=)"` literally — `tonumber` returns `nil`, and `tostring(nil or "")`
   evaluates to `""`. The line is **not** dropped on bad-count. Documents the
   tolerant-parser posture.
8. **`text` field preserves the full original sources cell.** A four-source
   input like `"link\t8\tnotes/a.md, notes/b.md, notes/c.md, notes/d.md"`
   produces one item where `filename = "notes/a.md"` but `text` contains the
   full comma-separated list. Distinguishes the `filename` (first-source)
   semantics from the `text` (full-context) semantics.
9. **Mixed-shape fixture.** A multi-line fixture combining: a single-source
   TSV line, a comma-separated multi-source TSV line, a no-`.md`-source TSV
   line (empty-filename fallback), a `<3`-tab line (skipped), a blank line
   (skipped), and a non-numeric-count TSV line. Expected item count and item
   values verified end-to-end.

The fixture lives at `tests/utils/obsidian_cli/fixtures/unresolved_verbose.txt`
and is read at spec time. The spec splits the file by `\n` and passes the
resulting list to `parsers.unresolved_verbose`. The fixture is a representative
hand-curated sample modeled after what `obsidian unresolved verbose` emits
(one logical row per unresolved link, tab-separated columns, sources list
comma-separated). Captured-by-hand, not a literal CLI run — same posture as
#15 / #16 / #17.

### Mutation-test recording

Not required by the parent — #15 already closed the "at least one parser has
a mutation test" criterion. This slice does not add another mutation
recording. Optional during implementation if the tester wants to confirm the
spec catches regressions; suggested mutation: in `parsers.unresolved_verbose`,
change `if #parts >= 3 then` to `if #parts >= 2 then`. Case 5
(`"two\tcells"` skip) turns red; revert restores green. Optional, not
committed.

## Acceptance criteria

- [ ] `tests/utils/obsidian_cli/command_spec.lua` is extended with one case
      asserting `command.unresolved()` returns the exact static string
      `"obsidian unresolved verbose"`. The existing `search_context`,
      `command.orphans` / `command.deadends`, and `command.tasks` cases
      remain unchanged and green.
- [ ] `tests/utils/obsidian_cli/parsers_spec.lua` is extended with at least
      nine new cases for `parsers.unresolved_verbose` covering: single-source
      TSV, comma-separated multi-source TSV, multiple TSV lines, no-`.md`
      empty-filename fallback, `<3`-tab skip, empty/whitespace skip,
      non-numeric count, full-sources preservation in `text`, and a
      mixed-shape fixture-driven case. The existing `search_context`, `paths`,
      and `tasks_verbose` cases remain unchanged and green.
- [ ] `tests/utils/obsidian_cli/fixtures/unresolved_verbose.txt` exists,
      contains a hand-curated mixed-shape sample (single-source TSV +
      comma-separated multi-source TSV + no-`.md` source TSV + a `<3`-tab
      line + a blank line + a non-numeric-count TSV line), and is read by
      the mixed-input `parsers.unresolved_verbose` spec at runtime.
- [ ] `./tests/run` exits 0 on the whole suite — the new cases plus
      everything from #14, #15, #16, #17, plus cycle 01's
      `wordcount_spec.lua`.
- [ ] `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exits 0. No shell
      call to `obsidian` happens during the new specs. (Carry-forward from
      #14 / #15 / #16 / #17 — the equivalent `PATH=/usr/bin:/bin` form fails
      because `nvim` lives in `/opt/homebrew/bin`; the spirit of the parent
      criterion is "obsidian absent from `$PATH`," which this form
      satisfies.)
- [ ] No reaching into local functions or monkey-patching globals in the new
      cases. `parsers.unresolved_verbose` and `command.unresolved` are
      exercised through their public module surface only.
- [ ] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is empty
      (carry-forward from parent — this slice does not edit the consumer).
- [ ] `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` shows no
      changes other than fixes-with-test (if any). Speculative parser or
      builder changes are out of scope.

## Proposed tests

| Title                                                                                          | What it verifies                                                                                                                                |
| ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `command.unresolved` returns the static `obsidian unresolved verbose` string                   | Exact equality. The `verbose` token is load-bearing.                                                                                            |
| `parsers.unresolved_verbose` parses a single-source TSV line                                   | Item shape: `filename = first_source`, `lnum = 1`, `col = 1`, `text = "<link> (count=<count>) sources: <sources>"`. Single-source pattern match. |
| `parsers.unresolved_verbose` parses a comma-separated multi-source TSV line                    | First `.md` source becomes `filename`; full sources string preserved in `text`. Delimited-tail pattern match.                                   |
| `parsers.unresolved_verbose` parses multiple TSV lines in order                                 | Two-line input → two items, order preserved. No shared state between iterations.                                                                |
| `parsers.unresolved_verbose` falls back to empty-string filename on no-`.md`-source            | `filename = ""` (not `nil`); item still emitted with full text. Documents degraded-non-dropping posture.                                        |
| `parsers.unresolved_verbose` skips lines with fewer than three tab parts                       | `"only-one"`, `"two\tcells"` yield no items. `>= 3` structural guard.                                                                           |
| `parsers.unresolved_verbose` skips empty and whitespace-only lines                              | `""`, `"   "` yield no items. Mixed with valid TSV, valid ones still appear.                                                                    |
| `parsers.unresolved_verbose` renders non-numeric count as empty string in `text`               | `"link\tnotanum\tsrc.md"` yields `text` containing `"(count=)"`. Tolerant-parser posture.                                                       |
| `parsers.unresolved_verbose` preserves the full sources cell in `text`                          | Four-source line: `filename` is first; `text` contains the full comma-separated list verbatim.                                                  |
| `parsers.unresolved_verbose` against a mixed-shape fixture                                      | End-to-end count and value check from `tests/utils/obsidian_cli/fixtures/unresolved_verbose.txt`.                                                |

A deliberate-failure / mutation verification is **not required** by this
slice. Optional and unrecorded.

## Affected artifacts

- Modified: `tests/utils/obsidian_cli/command_spec.lua` — extended with one
  new `command.unresolved` case.
- Modified: `tests/utils/obsidian_cli/parsers_spec.lua` — extended with at
  least nine new `parsers.unresolved_verbose` cases.
- New: `tests/utils/obsidian_cli/fixtures/unresolved_verbose.txt`
- Unchanged (verified by `git diff`): everything under
  `lua/utils/obsidian_cli/`, `lua/config/commands.lua`,
  `tests/utils/obsidian_cli/init_spec.lua`,
  `tests/utils/obsidian_cli/fixtures/search_context.txt`,
  `tests/utils/obsidian_cli/fixtures/paths.txt`,
  `tests/utils/obsidian_cli/fixtures/tasks_verbose.txt`, `tests/init.lua`,
  `tests/run`, `tests/utils/wordcount_spec.lua`.
- Unchanged: closed sibling sub-issue folders (`14-...`, `15-...`, `16-...`,
  `17-...`) — this slice does not edit them.
- **Updated at closure:** parent `issue.md` parser progress line (4 of 6,
  lists `unresolved_verbose` [#18]) — per `sdp-close` outward pass for an
  active artifact; the slice still closes no parent acceptance criterion
  outright and resolves no parent flag.
- New (closing artifact): `18-unresolved-verbose-builder-parser/aar.md` —
  records any deviations from this plan and notes the parser-coverage count
  after this slice (4 of 6).

## Dependencies

- **Sub-issue #14 (closed).** Provides `command.unresolved`,
  `parsers.unresolved_verbose`, the `tests/utils/obsidian_cli/` directory,
  and the layered module shape this slice tests against.
- **Sub-issue #15 (closed).** Established
  `tests/utils/obsidian_cli/command_spec.lua` and
  `tests/utils/obsidian_cli/parsers_spec.lua` and the
  `fixtures/search_context.txt` posture that this slice replicates for
  `unresolved_verbose.txt`.
- **Sub-issue #16 (closed).** Confirmed the static-builder
  `command_spec.lua`-extension pattern (`command.orphans` /
  `command.deadends`); this slice reuses that pattern verbatim for
  `command.unresolved`.
- **Sub-issue #17 (closed).** Confirmed the parser-coverage outward-pass
  posture (update parent `issue.md` parser progress line at closure) — this
  slice continues that pattern for the 3/6 → 4/6 advance.
- **ADR-0001** — `mini.test` runner. Accepted.
- **ADR-0002** — folder slug `18-...` tracks GitHub issue number.
  Confirm `#18` at activation; rename folder if the actual issue gets a
  different number.
- No dependency on any other parent or any other cycle.

## Out of scope (deferred to later #18+ slices)

- Parser tests for `backlinks_json` and `extract_bookmark_note_path`. Each
  is a separate slice. Parent acceptance criterion "every parser has at
  least one passing unit test" is **partially advanced** by this slice
  (4 of 6 parsers covered after closure), not closed.
- Command-builder tests for the remaining builders (`history_list`,
  `history_read`, `diff`, `outline`, `backlinks_counts`, `wordcount`,
  `bookmarks_verbose`, `bookmark_add`, `task_toggle`). The parent's
  command-builder shell-escape criterion is already closed by #15. Future
  per-leaf builder specs are nice-to-have, not required.
- Integration-style coverage of `init.lua`'s `M.unresolved_to_quickfix`
  composition. That leaf calls `shell.run`, `presenter.scratch`, and
  `vim.fn.setqflist`, and exposes three distinct user-facing message
  shapes ("Loaded N unresolved link(s)…", "No unresolved links parsed.
  Opened raw output buffer.", "No unresolved links."). Testing the
  composition requires the shell seam plus quickfix/scratch state
  assertions, or a child-Neovim spec. Defer to a presenter-testability
  slice. The two no-items branches in particular (parsed-zero-with-raw vs
  empty-CLI-output) are integration-path coverage that pure-parser tests
  cannot reach — the parser only sees `lines`, never the upstream
  `lines == nil` / `#lines == 0` distinction.
- Backlinks integration coverage. **Parent flag remains active and
  unchanged.**
- Bookmark parser tests. **Parent flag remains active and unchanged**;
  pre-document step is still required before that slice activates.
- Any ADR-0003 work. Reserved for the final sub-issue.
- Any edits to `lua/utils/obsidian_cli/` modules unless the new specs reveal
  a defect (fix-with-test only).

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
  exercised by `./tests/run`." — **4 of 6 parsers covered** after
  closure (`search_context` from #15 + `paths` from #16 + `tasks_verbose`
  from #17 + `unresolved_verbose` from this slice). Two remain:
  `backlinks_json`, `extract_bookmark_note_path`.

### Parent acceptance criteria this slice maintains (does not regress)

- `./tests/run` exits 0 on the whole suite.
- `PATH=...` test suite green with `obsidian` absent.
- `git diff` against `lua/config/commands.lua` empty.
- No reaching into local functions or monkey-patching internals.

### Parent flags this slice resolves or updates

- **Backlinks-parser flag (`#14 AAR → backlinks-parser sub-issue`):**
  unchanged. Stays active for the backlinks slice.
- **Bookmark-parser flag (`#14 AAR → bookmark-parser sub-issue`):**
  unchanged. Stays active and the pre-document step is still required
  for that slice.

### Outward pass — parent issue updates after closure

On closure, update parent `issue.md` parser progress line (lines 29–31) to
"Progress as of #18: 4 of 6" and add `unresolved_verbose` [#18] to the
covered list — per `sdp-close` for an active artifact, mirroring #17's
outward pass.

This slice's AAR also records:

- Parser-coverage advance: `3/6 → 4/6` (redundant with parent text; AAR is
  the audit trail).
- Any deviations from the proposed test list, with rationale.
- Any defects-fixed-with-test in `parsers.unresolved_verbose` or
  `command.unresolved` (none expected).
- Any new flag if the implementation surfaces an unresolvable nuance.
  Likely candidates worth recording (only if observed): ambiguity in the
  first-source pattern when sources contain `.md` substrings inside other
  tokens (e.g., `notes/foo.md.bak` — does the non-greedy `[^,%s]+%.md`
  match correctly?), or fixture lines that produce a surprising
  empty-filename count.

No new flags expected — `parsers.unresolved_verbose` is structurally
simpler than `parsers.tasks_verbose` (no carried state, no header
detection). If a nuance surfaces, record it as a flag in this sub-issue's
AAR.

## Suggested GitHub issue title

`feature: parser-pass slice — unresolved_verbose builder + parser (TSV link/count/sources)`

Alternative shorter forms:

- `feature: unresolved_verbose parser specs + command.unresolved builder spec`
- `test: unresolved_verbose parser (TSV) + command.unresolved builder`
