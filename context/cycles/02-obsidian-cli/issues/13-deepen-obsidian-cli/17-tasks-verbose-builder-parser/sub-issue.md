# Sub-issue — tasks_verbose builder + parser (grouped-by-file)

**Status: closed** — see `17-tasks-verbose-builder-parser/aar.md`.

GitHub issue: #17 (folder slug per ADR-0002). Fourth sub-issue of parent
#13. The third parser-pass slice after #15 (`search_context`) and #16 (`paths`).
Lands the unit tests for `parsers.tasks_verbose` (the grouped-by-file format
produced by `obsidian tasks [todo] verbose`) and the non-trivial command-builder
`command.tasks(opts)` whose `only_todo` flag toggles a positional argument.
Picked from the parent issue's sequencing list (`issue.md` line 109:
"`tasks_verbose_to_items` — the grouped-by-file format") — first item still open
after #16 closed `paths`.

Engages neither parent flag. The backlinks-parser flag
(`#14 AAR → backlinks-parser sub-issue`) and the bookmark-parser flag
(`#14 AAR → bookmark-parser sub-issue`) remain active and unmodified; this slice
does not touch `parsers.backlinks_json`, `parsers.extract_bookmark_note_path`,
or the `M.backlinks_counts_to_quickfix` integration path.

## Description

Add unit tests for two leaf modules already in place from #14:

- `command.tasks(opts)` — exercise the only command-builder leaf in the cycle
  that varies its output on a non-string option (`opts.only_todo`). Three
  observable shapes:
  1. `command.tasks()` and `command.tasks({})` → `"obsidian tasks todo verbose"`
     (the `only_todo` default is `true`).
  2. `command.tasks({ only_todo = true })` → `"obsidian tasks todo verbose"`.
  3. `command.tasks({ only_todo = false })` → `"obsidian tasks verbose"` (the
     `todo` token is dropped). No shell-escape involvement — the option is a
     boolean, not a user string. Regression-guard for the only branching
     builder; future restructuring of `command.lua` that swaps the variant logic
     would be caught.

- `parsers.tasks_verbose(lines)` — exercise the grouped-by-file transformation.
  The parser is the most stateful of the six (carries a `current_file` across
  iterations) and has the largest input-shape surface. Three classes of accepted
  input:
  1. **File-header line** — a path ending in `.md` with no `:<digits>` pattern
     and no `[ ]`/`[x]`/`[?]`/`[-]` checkbox. Sets `current_file`; produces no
     item itself.
  2. **Inline `path:line:text` / `path:line text` / TSV lines** — handled by the
     shared private `parse_path_line_text` helper (already covered for
     `search_context` in #15 — this slice asserts equivalent behavior holds when
     reached via `tasks_verbose`).
  3. **Header-relative `lnum: text` / `lnum text` lines** — when no inline path
     is present and `current_file` is set, lines starting with digits attach to
     `current_file`. The fallback regex (`^%s*(%d+):%s*(.*)$` then
     `^%s*(%d+)%s+(.*)$`) is unique to this parser.

  Output items carry an extra `user_data.obsidian_task_ref` of shape
  `<path>:<lnum>` — a property the other parsers do not produce. Specs assert it
  explicitly.

No production code changes are required. Both `command.tasks` and
`parsers.tasks_verbose` already exist from #14; this slice adds their tests and
one fixture file (`tasks_verbose.txt`). If the tests reveal a defect in the
existing implementation, fix-with-test stays in scope; speculative parser or
builder changes do not.

## Dependency classification

| Dependency                                 | Category                 | Testing strategy                                                                                                                  |
| ------------------------------------------ | ------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `obsidian` CLI binary                      | True external (platform) | Not invoked. Specs read fixture text from disk; the command builder returns strings and never executes them.                      |
| `vim.fn.shellescape`                       | In-process (Neovim API)  | Not exercised by this slice — `command.tasks` does not call it (no string argument is shell-interpolated).                        |
| `vim.fn.systemlist`                        | In-process (Neovim API)  | Not exercised. Shell seam stays untouched.                                                                                        |
| `vim.trim`, `vim.split`, `vim.list_slice`  | In-process (Neovim API)  | Used by `parsers.tasks_verbose` and the private `parse_path_line_text` against fixture-derived inputs. No stub.                   |
| Lua patterns (`string.match`)              | In-process               | Used by header-detection guard, fallback `lnum`-prefixed regex, and `parse_path_line_text`. Tested via observable parser output.  |
| `lua/config/vaults.lua` (`VAULT_ROOTS`)    | In-process               | Loaded transitively when `parsers.lua` is required. No test substitution — same posture as #14 / #15 / #16.                       |
| `mini.test`                                | In-process               | Loaded via cycle 01's harness. Spec runs through `./tests/run`.                                                                   |
| Captured CLI fixture (`tasks_verbose.txt`) | Test artifact            | Plain text under `tests/utils/obsidian_cli/fixtures/`, read by the spec via `io.open`. Documented as captured-by-hand in the AAR. |

No new seams introduced. The shell-adapter seam from #14 is **not** exercised —
both modules under test are pure with respect to shell execution.

## Interface design / scope

The interfaces under test are already finalized in #14. This slice's "interface
design" is the **test surface** — what the spec asserts and what it does not.

### `command.tasks` test surface

The spec requires the public `command` module and calls `command.tasks(opts)`
directly. No reaching into locals; the private `shellescape` alias is not
referenced.

New cases extend the existing `tests/utils/obsidian_cli/command_spec.lua` file
(created in #15, extended in #16). They sit alongside the five `search_context`
cases and the two static-builder cases already there.

Assertions cover:

1. **Default invocation includes `todo`.** `command.tasks()` returns the exact
   string `"obsidian tasks todo verbose"`. Guards the `only_todo ~= false`
   default.
2. **Empty-table opts behaves as default.** `command.tasks({})` returns the same
   `"obsidian tasks todo verbose"`. Guards the `opts = opts or {}` guard plus
   the default branch in one shot.
3. **Explicit `only_todo = true`.** `command.tasks({ only_todo = true })`
   returns `"obsidian tasks todo verbose"`. Symmetric with case 1; documents the
   explicit-true caller path.
4. **Explicit `only_todo = false` drops the `todo` token.**
   `command.tasks({ only_todo = false })` returns `"obsidian tasks verbose"`.
   Guards the only-branch — the production caller
   `M.tasks_to_quickfix({ only_todo = false, ... })` (`init.lua:420`) depends on
   this exact shape.

### `parsers.tasks_verbose` test surface

Spec requires `utils.obsidian_cli.parsers` and calls
`parsers.tasks_verbose(lines)` against fixture-derived inputs. The new cases
extend the existing `tests/utils/obsidian_cli/parsers_spec.lua` file.

Assertions cover:

1. **Grouped block — header + lnum-text rows.** Input:
   ```
   notes/work.md
     12: - [ ] Write the spec
     18: - [ ] Land the PR
   ```
   Produces two items, both with `filename = "notes/work.md"`, `lnum`s `12` and
   `18`, `text` equal to the trimmed task line, `col = 1`, and
   `user_data.obsidian_task_ref` equal to `"notes/work.md:12"` /
   `"notes/work.md:18"` respectively. Both fallback shapes (`<n>: <rest>` and
   `<n> <rest>`) get one case each — a second sub-block exercises
   `^%s*(%d+)%s+(.*)$` (no colon after the digit).
2. **Multiple header sections in sequence.** Input alternates two file headers,
   each followed by one or more lnum-text rows. Verifies `current_file` is
   correctly carried and replaced. The output preserves input order.
3. **Inline `path:line:text` line (no enclosing header).** A standalone
   `notes/standalone.md:7: inline task` line — common shape if the CLI emits an
   inline form interleaved with grouped sections. The parser delegates to
   `parse_path_line_text` and produces an item with
   `filename = "notes/standalone.md"`, `lnum = 7`, `text = "inline task"`, and
   `user_data.obsidian_task_ref = "notes/standalone.md:7"`.
4. **Header-detection guard rejects path-with-line-suffix lines.** A line
   `notes/foo.md:42: x` is **not** treated as a header (it contains `:%d+`); the
   parser routes it through `parse_path_line_text` and produces an item.
   Distinguishes the header branch from the inline branch.
5. **Header-detection guard rejects task-shaped lines.** A line
   `notes/foo.md - [ ] something` is **not** treated as a header (it contains a
   checkbox `[ ]`). The parser routes it through `parse_path_line_text`; this
   shape does not match any of the three inline patterns and yields no item —
   the line is silently skipped. Documents the boundary between "looks like a
   header" and "looks like a task line."
6. **`user_data.obsidian_task_ref` round-trip.** A header-relative item produces
   `user_data.obsidian_task_ref = "<header path>:<lnum>"`; an inline-shape item
   produces `user_data.obsidian_task_ref = "<inline path>:<lnum>"`. Asserted
   explicitly because no other parser produces `user_data` and downstream
   `M.toggle_task_at_cursor` (`init.lua:420`) depends on this exact shape.
7. **Skips empty lines.** Empty strings and whitespace-only lines yield no items
   and do not reset `current_file`. Mixed with valid grouped rows, the valid
   ones still appear under the prior header.
8. **Mixed-shape fixture.** A multi-line fixture combining: a header with two
   lnum-colon-text rows, a header with one lnum-space-text row, an interleaved
   standalone `path:line:text` line, blank lines, and a line that looks like a
   header but carries a `:digits` suffix (which falls through to
   `parse_path_line_text`). Expected item count and item values verified
   end-to-end.

The fixture lives at `tests/utils/obsidian_cli/fixtures/tasks_verbose.txt` and
is read at spec time. The spec splits the file by `\n` and passes the resulting
list to `parsers.tasks_verbose`. The fixture is a representative hand-curated
sample modeled after what `obsidian tasks todo verbose` emits (file headers
followed by indented `<lnum>: <task line>` rows). Captured-by-hand, not a
literal CLI run — same posture as #15 / #16.

### Mutation-test recording

Not required by the parent — #15 already closed the "at least one parser has a
mutation test" criterion. This slice does not add another mutation recording.
Optional during implementation if the tester wants to confirm the spec catches
regressions; suggested mutation: in `parsers.tasks_verbose`, change the header
guard
`if file_header:match("%.md$") and not file_header:match(":%d+") and not file_header:match("%[%s*[xX %-%?]%s*%]")`
to drop the `:%d+` clause. Cases 4 and 8 turn red; revert restores green.
Optional, not committed.

## Acceptance criteria

- [x] `tests/utils/obsidian_cli/command_spec.lua` is extended with four cases
      covering `command.tasks` defaults, empty-table opts, explicit
      `only_todo = true`, and explicit `only_todo = false`. The existing five
      `search_context` cases and two static-builder cases (`orphans`,
      `deadends`) remain unchanged and green.
- [x] `tests/utils/obsidian_cli/parsers_spec.lua` is extended with at least
      eight new cases for `parsers.tasks_verbose` covering: grouped block
      (lnum-colon-text and lnum-space-text), multiple header sections, inline
      `path:line:text`, header-guard against `:digits` lines, header-guard
      against checkbox-shaped lines, `user_data.obsidian_task_ref` round-trip,
      empty-line skip, and a mixed-shape fixture-driven case. The existing
      `search_context` and `paths` cases remain unchanged and green.
- [x] `tests/utils/obsidian_cli/fixtures/tasks_verbose.txt` exists, contains a
      hand-curated mixed-shape sample (two header sections of differing
      lnum-text shape + one interleaved inline `path:line:text` line + blanks +
      one header-shaped line carrying `:digits` suffix), and is read by the
      mixed-input `parsers.tasks_verbose` spec at runtime.
- [x] `./tests/run` exits 0 on the whole suite — the new cases plus everything
      from #14, #15, #16, plus cycle 01's `wordcount_spec.lua`.
- [x] `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exits 0. No shell call
      to `obsidian` happens during the new specs. (Carry-forward from #14 / #15
      / #16 — the equivalent `PATH=/usr/bin:/bin` form fails because `nvim`
      lives in `/opt/homebrew/bin`; the spirit of the parent criterion is
      "obsidian absent from `$PATH`," which this form satisfies.)
- [x] No reaching into local functions or monkey-patching globals in the new
      cases. `parsers.tasks_verbose` and `command.tasks` are exercised through
      their public module surface only. The private `parse_path_line_text`
      helper is exercised transitively, never directly.
- [x] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is empty
      (carry-forward from parent — this slice does not edit the consumer).
- [x] `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` shows no changes
      other than fixes-with-test (if any). Speculative parser or builder changes
      are out of scope.

## Proposed tests

| Title                                                                                        | What it verifies                                                                                                                                                  |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `command.tasks` defaults to `obsidian tasks todo verbose`                                    | `command.tasks()` returns the default-todo string. Default-branch coverage.                                                                                       |
| `command.tasks({})` matches the default                                                      | Empty-table opts coerced through `opts or {}` and `~= false` guard.                                                                                               |
| `command.tasks({ only_todo = true })` returns `obsidian tasks todo verbose`                  | Explicit-true caller path.                                                                                                                                        |
| `command.tasks({ only_todo = false })` returns `obsidian tasks verbose`                      | Drop-`todo` branch — the only branching path in the builder.                                                                                                      |
| `parsers.tasks_verbose` parses a grouped block (lnum-colon-text)                             | Header sets `current_file`; two `<n>: <rest>` rows produce two items with correct `filename`, `lnum`, `text`, `user_data.obsidian_task_ref`, and order preserved. |
| `parsers.tasks_verbose` parses a grouped block (lnum-space-text)                             | Same as above but rows shaped `<n> <rest>` (no colon after digit).                                                                                                |
| `parsers.tasks_verbose` parses multiple header sections in sequence                          | `current_file` is replaced when a new header arrives; rows attach to the most-recent header in input order.                                                       |
| `parsers.tasks_verbose` parses an inline `path:line:text` line outside any header            | Delegation to `parse_path_line_text` produces an item with `user_data.obsidian_task_ref` = `<inline path>:<lnum>`.                                                |
| `parsers.tasks_verbose` does not treat a `path.md:N: ...` line as a header                   | `:%d+` guard routes the line through `parse_path_line_text`; produces one item, not a header.                                                                     |
| `parsers.tasks_verbose` does not treat a `path.md - [ ] ...` line as a header                | Checkbox guard routes the line through `parse_path_line_text`; that helper finds no inline pattern, so the line is silently skipped.                              |
| `parsers.tasks_verbose` populates `user_data.obsidian_task_ref` for header-relative items    | `<header path>:<lnum>` shape, used by `M.toggle_task_at_cursor`.                                                                                                  |
| `parsers.tasks_verbose` skips empty and whitespace-only lines without resetting current file | Blank lines do not nil out `current_file`; subsequent lnum-text rows still attach correctly.                                                                      |
| `parsers.tasks_verbose` against a mixed-shape fixture                                        | End-to-end count and value check from `tests/utils/obsidian_cli/fixtures/tasks_verbose.txt`.                                                                      |

A deliberate-failure / mutation verification is **not required** by this slice.
Optional and unrecorded.

## Affected artifacts

- Modified: `tests/utils/obsidian_cli/command_spec.lua` — extended with four new
  `command.tasks` cases.
- Modified: `tests/utils/obsidian_cli/parsers_spec.lua` — extended with at least
  eight new `parsers.tasks_verbose` cases.
- New: `tests/utils/obsidian_cli/fixtures/tasks_verbose.txt`
- Unchanged (verified by `git diff`): everything under
  `lua/utils/obsidian_cli/`, `lua/config/commands.lua`,
  `tests/utils/obsidian_cli/init_spec.lua`,
  `tests/utils/obsidian_cli/fixtures/search_context.txt`,
  `tests/utils/obsidian_cli/fixtures/paths.txt`, `tests/init.lua`, `tests/run`,
  `tests/utils/wordcount_spec.lua`.
- Unchanged: closed sibling sub-issue folders (`14-...`, `15-...`, `16-...`) —
  this slice does not edit them.
- **Updated at closure:** parent `issue.md` parser progress line (3 of 6, lists
  `tasks_verbose` [#17]) — per `sdp-close` outward pass for an active artifact;
  the slice still closes no parent acceptance criterion outright and resolves
  no parent flag.
- New (closing artifact): `17-tasks-verbose-builder-parser/aar.md` — records any
  deviations from this plan and notes the parser-coverage count after this slice
  (3 of 6).

## Dependencies

- **Sub-issue #14 (closed).** Provides `command.tasks`, `parsers.tasks_verbose`,
  the private `parse_path_line_text` helper, the `tests/utils/obsidian_cli/`
  directory, and the layered module shape this slice tests against.
- **Sub-issue #15 (closed).** Established
  `tests/utils/obsidian_cli/command_spec.lua` and
  `tests/utils/obsidian_cli/parsers_spec.lua` and the
  `fixtures/search_context.txt` posture that this slice replicates for
  `tasks_verbose.txt`.
- **Sub-issue #16 (closed).** Confirmed the `command_spec.lua`-extension pattern
  for static / non-shellescape builders; this slice extends the same file with
  the only branching builder.
- **ADR-0001** — `mini.test` runner. Accepted.
- **ADR-0002** — folder slug `17-...` tracks GitHub issue number `#17`
  (confirmed).
- No dependency on any other parent or any other cycle.

## Out of scope (deferred to later #17+ slices)

- Parser tests for `unresolved_verbose`, `backlinks_json`,
  `extract_bookmark_note_path`. Each is a separate slice. Parent acceptance
  criterion "every parser has at least one passing unit test" is **partially
  advanced** by this slice (3 of 6 parsers covered after closure), not closed.
- Command-builder tests for the remaining builders (`unresolved`,
  `history_list`, `history_read`, `diff`, `outline`, `backlinks_counts`,
  `wordcount`, `bookmarks_verbose`, `bookmark_add`, `task_toggle`). The parent's
  command-builder shell-escape criterion is already closed by #15. Future
  per-leaf builder specs are nice-to-have, not required.
- Integration-style coverage of `init.lua`'s `tasks_to_quickfix` /
  `toggle_task_at_cursor` compositions. Those leaves call `shell.run` and
  `presenter.to_quickfix`; testing the composition requires the shell seam plus
  quickfix state assertions, or a child-Neovim spec. Defer to a
  presenter-testability slice.
- Backlinks integration coverage. **Parent flag remains active and unchanged.**
- Bookmark parser tests. **Parent flag remains active and unchanged**;
  pre-document step is still required before that slice activates.
- Any ADR-0003 work. Reserved for the final sub-issue.
- Any edits to `lua/utils/obsidian_cli/` modules unless the new specs reveal a
  defect (fix-with-test only).

## Pre-activation review (parent linkage)

### Parent acceptance criteria this slice closes outright

None. The remaining open parser criterion ("every parser has a unit test") is
multi-shot — only fully closed once all six parsers have specs. The other open
parent criteria (`init.lua`-export parity, layered sibling presence, single
shell-call grep, `set_runner`/`reset_runner` exposure, `commands.lua` diff
empty, ADR-0003 decision) sit outside this slice's scope.

### Parent acceptance criteria this slice partially advances

- "Every output parser introduced or extracted by the deepening has at least one
  passing unit test under `tests/utils/obsidian_cli/`, exercised by
  `./tests/run`." — **3 of 6 parsers covered** after closure (`search_context`
  from #15 + `paths` from #16 + `tasks_verbose` from this slice). Three remain:
  `unresolved_verbose`, `backlinks_json`, `extract_bookmark_note_path`.

### Parent acceptance criteria this slice maintains (does not regress)

- `./tests/run` exits 0 on the whole suite.
- `PATH=...` test suite green with `obsidian` absent.
- `git diff` against `lua/config/commands.lua` empty.
- No reaching into local functions or monkey-patching internals.

### Parent flags this slice resolves or updates

- **Backlinks-parser flag (`#14 AAR → backlinks-parser sub-issue`):** unchanged.
  Stays active for the backlinks slice.
- **Bookmark-parser flag (`#14 AAR → bookmark-parser sub-issue`):** unchanged.
  Stays active and the pre-document step is still required for that slice.

### Outward pass — parent issue updates after closure

**Done:** Parser progress in parent `issue.md` (lines 29–31) updated to
`Progress as of #17: 3 of 6` with `tasks_verbose` [#17] listed.

On closure, this slice's AAR also records:

- Parser-coverage advance: `2/6 → 3/6` (redundant with parent text; AAR is the
  audit trail).
- Any deviations from the proposed test list, with rationale.
- Any defects-fixed-with-test in `parsers.tasks_verbose` or `command.tasks`
  (none expected).
- Any new flag if the implementation surfaces an unresolvable nuance. None
  expected — the parser is more stateful than `parsers.paths` but has no
  external dependencies the slice does not already understand.

No new flags expected. If a nuance surfaces (likely candidates: ambiguity in the
header guard's interaction with `parse_path_line_text`, or fixture lines that
produce a surprising item count), record it as a flag in this sub-issue's AAR.

## Suggested GitHub issue title

`feature: parser-pass slice — tasks_verbose builder + parser (grouped-by-file)`

Alternative shorter forms:

- `feature: tasks_verbose parser specs + command.tasks builder spec`
- `test: tasks_verbose parser (grouped-by-file) + command.tasks builder`
