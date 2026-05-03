# Sub-issue — paths parser (orphans + deadends)

GitHub issue: #16 (provisional — confirm at activation, rename folder per
ADR-0002 if the assigned number differs). Third sub-issue of parent #13. The
second parser-pass slice after the #15 `search:context` slice. Lands the unit
test for `parsers.paths` (the only parser shared between two leaves —
`orphans_to_quickfix` and `deadends_to_quickfix`) and the two trivial
command-builder specs that go with it. Picked from the parent issue's
sequencing list (`issue.md` line 105: "`paths_to_quickfix` family — orphans,
deadends") — first item still open after #15 closed `parse_path_line_text`.

Engages neither parent flag. The backlinks-parser flag and the
bookmark-parser flag remain active and unmodified.

## Description

Add unit tests for two leaf modules already in place from #14:

- `command.orphans()` and `command.deadends()` — exercise the two static
  command-builder leaves. No arguments, no shell-escape, no shape variation;
  each returns a fixed string. Trivial but a load-bearing regression guard:
  any future restructuring of `command.lua` that swaps the strings would be
  caught by these specs.
- `parsers.paths(lines)` — exercise the plain-path-line transformation
  shared between `orphans_to_quickfix` and `deadends_to_quickfix`. The parser
  has three observable behaviors: items for non-empty trimmed lines, skip on
  empty/whitespace-only lines, skip on the literal `total` trailer that
  `obsidian orphans` and `obsidian deadends` emit at the end of their output.

No production code changes are required. Both `command.orphans` /
`command.deadends` and `parsers.paths` already exist from #14; this slice
adds their tests and one fixture file (`paths.txt`). If the tests reveal a
defect in the existing implementation, fix-with-test stays in scope;
speculative parser changes do not.

## Dependency classification

| Dependency                                           | Category                  | Testing strategy                                                                                                                          |
| ---------------------------------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `obsidian` CLI binary                                | True external (platform)  | Not invoked. Specs read fixture text from disk; the command builders return strings and never execute them.                                |
| `vim.fn.shellescape`                                 | In-process (Neovim API)   | Not exercised by this slice — neither `command.orphans` nor `command.deadends` calls it. They are static-string builders.                  |
| `vim.fn.systemlist`                                  | In-process (Neovim API)   | Not exercised. Shell seam stays untouched.                                                                                                |
| `vim.trim`, `vim.split`                              | In-process (Neovim API)   | Used by `parsers.paths` against fixture-derived inputs. No stub.                                                                          |
| `lua/config/vaults.lua` (`VAULT_ROOTS`)              | In-process                | Loaded transitively when `parsers.lua` is required. No test substitution — same posture as #14 / #15.                                      |
| `mini.test`                                          | In-process                | Loaded via cycle 01's harness. Spec runs through `./tests/run`.                                                                            |
| Captured CLI fixture (`paths.txt`)                   | Test artifact             | Plain text under `tests/utils/obsidian_cli/fixtures/`, read by the spec via `io.open`. Documented as captured-by-hand in the AAR.          |

No new seams introduced. The shell-adapter seam from #14 is **not** exercised
— both modules under test are pure with respect to shell execution.

## Interface design / scope

The interfaces under test are already finalized in #14. This slice's
"interface design" is the **test surface** — what the spec asserts and what
it does not.

### `command.orphans` / `command.deadends` test surface

The specs require the public `command` module and call the two builders
directly. No reaching into locals; the private `shellescape` alias is not
referenced.

Assertions cover:

1. **`command.orphans()` returns the exact string `"obsidian orphans"`.**
   Hardcoded comparison — no `shellescape` composition needed because the
   builder takes no arguments.
2. **`command.deadends()` returns the exact string `"obsidian deadends"`.**
   Same shape, hardcoded comparison.

Both new cases extend the existing `tests/utils/obsidian_cli/command_spec.lua`
file (created in #15). They sit alongside the five `search_context` cases
already there.

### `parsers.paths` test surface

Spec requires `utils.obsidian_cli.parsers` and calls `parsers.paths(lines)`
against fixture-derived inputs. The new cases extend the existing
`tests/utils/obsidian_cli/parsers_spec.lua` file.

Assertions cover:

1. **Plain path lines.** A list with one entry `"notes/foo.md"` produces one
   item shaped `{ filename = "notes/foo.md", lnum = 1, col = 1, text = "notes/foo.md" }`.
2. **Multiple path lines.** A two-line list produces two items in order.
3. **Skips empty lines.** Empty strings and whitespace-only lines yield no
   items. Mixed with valid lines, the valid ones still appear.
4. **Skips the `total` trailer.** A line equal to `"total"` (with optional
   surrounding whitespace) yields no item. Verifies the
   `^%s*total%s*$` guard. The non-anchored case `"total: 12"` already
   exercised by `search_context` malformed-line spec is *not* relevant here
   — `parsers.paths` would in fact accept that as a path because it has no
   path-shape filter beyond the `total` guard. Document this in the AAR if
   the test surface tempts a surprise; it is intentional (`obsidian orphans`
   never emits `total: 12`, only the bare word `total` followed by a count
   line).
5. **Trims surrounding whitespace.** A line `"  notes/spaced.md  "` produces
   an item with `filename = "notes/spaced.md"` (trimmed). This is the only
   transformation `parsers.paths` performs beyond the skip filters.
6. **Mixed-input fixture.** A multi-line fixture combining valid path lines,
   blanks, whitespace-only lines, and a `total` trailer produces exactly the
   expected item count and item values, end-to-end.

The fixture lives at `tests/utils/obsidian_cli/fixtures/paths.txt` and is
read at spec time. The spec splits the file by `\n` and passes the
resulting list to `parsers.paths`. The fixture is a representative
hand-curated sample modeled after what `obsidian orphans` and
`obsidian deadends` emit (one path per line, blank lines uncommon but
possible, terminating `total\n<count>` trailer). Captured-by-hand, not a
literal CLI run — same posture as #15.

### Mutation-test recording

Not required by the parent — #15 already closed the "at least one parser has
a mutation test" criterion. This slice does not add another mutation
recording. If a tester wants to confirm the spec catches regressions during
implementation (recommended, optional), suggested mutation: in
`parsers.paths`, change `not p:match("^%s*total%s*$")` to
`not p:match("never matches")`. The fixture spec turns red; revert restores
green. Optional, not committed.

## Acceptance criteria

- [ ] `tests/utils/obsidian_cli/command_spec.lua` is extended with two
      cases asserting `command.orphans()` and `command.deadends()` return
      their exact static command strings. The existing five
      `search_context` cases remain unchanged and green.
- [ ] `tests/utils/obsidian_cli/parsers_spec.lua` is extended with at
      least six new cases for `parsers.paths` covering: single path,
      multiple paths, empty-line skip, `total`-trailer skip,
      whitespace-trim, and a multi-shape fixture-driven mixed input. The
      existing `search_context` cases remain unchanged and green.
- [ ] `tests/utils/obsidian_cli/fixtures/paths.txt` exists, contains a
      hand-curated mixed-shape sample (valid paths + blanks + `total`
      trailer + whitespace-padded path), and is read by the mixed-input
      `parsers.paths` spec at runtime.
- [ ] `./tests/run` exits 0 on the whole suite — the new cases plus the
      #14 tracer plus #15's `search_context` cases plus cycle 01's
      `wordcount_spec.lua`.
- [ ] `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exits 0. No shell
      call to `obsidian` happens during the new specs. (Carry-forward from
      #14 / #15 — the equivalent `PATH=/usr/bin:/bin` form fails because
      `nvim` lives in `/opt/homebrew/bin`; the spirit of the parent
      criterion is "obsidian absent from `$PATH`," which this form
      satisfies.)
- [ ] No reaching into local functions or monkey-patching globals in the
      new cases. `parsers.paths` and the two command builders are
      exercised through their public module surface only.
- [ ] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is empty
      (carry-forward from parent — this slice does not edit the consumer).
- [ ] `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` shows no
      changes other than fixes-with-test (if any). Speculative parser or
      builder changes are out of scope.

## Proposed tests

| Title                                                                          | What it verifies                                                                                                       |
| ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `command.orphans` returns the static `obsidian orphans` string                  | Exact equality.                                                                                                        |
| `command.deadends` returns the static `obsidian deadends` string                | Exact equality.                                                                                                        |
| `parsers.paths` parses a single path line                                       | Item shape: `{ filename, lnum=1, col=1, text=path }`.                                                                  |
| `parsers.paths` parses multiple path lines in order                             | Two-line input → two items, order preserved.                                                                           |
| `parsers.paths` skips empty and whitespace-only lines                           | `""`, `"   "`, `"\t"` produce no items; mixed with valid lines, valid ones still appear.                              |
| `parsers.paths` skips the `total` trailer                                       | `"total"` (with surrounding whitespace) produces no item.                                                              |
| `parsers.paths` trims surrounding whitespace                                    | `"  notes/spaced.md  "` → `filename = "notes/spaced.md"`.                                                              |
| `parsers.paths` against a mixed-shape fixture                                   | End-to-end count and value check from `tests/utils/obsidian_cli/fixtures/paths.txt`.                                    |

A deliberate-failure / mutation verification is **not required** by this
slice. Optional and unrecorded.

## Affected artifacts

- Modified: `tests/utils/obsidian_cli/command_spec.lua` — extended with
  two new cases.
- Modified: `tests/utils/obsidian_cli/parsers_spec.lua` — extended with
  six new `parsers.paths` cases.
- New: `tests/utils/obsidian_cli/fixtures/paths.txt`
- Unchanged (verified by `git diff`): everything under
  `lua/utils/obsidian_cli/`, `lua/config/commands.lua`,
  `tests/utils/obsidian_cli/init_spec.lua`,
  `tests/utils/obsidian_cli/fixtures/search_context.txt`,
  `tests/init.lua`, `tests/run`, `tests/utils/wordcount_spec.lua`.
- Unchanged: parent `issue.md` (the slice closes no parent acceptance
  criteria outright — see pre-activation review — and resolves no parent
  flag).
- New (closing artifact): `16-paths-parser-orphans-deadends/aar.md` —
  records any deviations from this plan and notes the parser-coverage
  count after this slice (2 of 6).

## Dependencies

- **Sub-issue #14 (closed).** Provides `command.orphans`,
  `command.deadends`, `parsers.paths`, the
  `tests/utils/obsidian_cli/` directory, and the layered module shape
  this slice tests against.
- **Sub-issue #15 (closed).** Established
  `tests/utils/obsidian_cli/command_spec.lua` and
  `tests/utils/obsidian_cli/parsers_spec.lua` — this slice extends both
  rather than creating new files.
- **ADR-0001** — `mini.test` runner. Accepted.
- **ADR-0002** — folder slug `16-...` tracks GitHub issue number.
  Confirm `#16` at activation; rename folder if the actual issue gets a
  different number.
- No dependency on any other parent or any other cycle.

## Out of scope (deferred to later #16+ slices)

- Parser tests for `tasks_verbose`, `unresolved_verbose`,
  `backlinks_json`, `extract_bookmark_note_path`. Each is a separate
  slice. Parent acceptance criterion "every parser has at least one
  passing unit test" is **partially advanced** by this slice (2 of 6
  parsers covered after closure), not closed.
- Command-builder tests for the remaining builders (`tasks`,
  `unresolved`, `history_list`, `history_read`, `diff`, `outline`,
  `backlinks_counts`, `wordcount`, `bookmarks_verbose`, `bookmark_add`,
  `task_toggle`). The parent's command-builder criterion is already
  closed by #15. Future per-leaf builder specs are nice-to-have, not
  required.
- Integration-style coverage of `init.lua`'s `orphans_to_quickfix` /
  `deadends_to_quickfix` compositions. Those leaves call
  `presenter.to_quickfix`; testing the composition requires either the
  shell seam plus quickfix state assertions or a child-Neovim spec.
  Defer to a presenter-testability slice.
- Backlinks integration coverage. Parent flag remains active.
- Bookmark parser tests. Parent flag remains active and pre-document
  step is still required before that slice activates.
- Any ADR-0003 work. Reserved for the final sub-issue.
- Any edits to `lua/utils/obsidian_cli/` modules unless the new specs
  reveal a defect (fix-with-test only).

## Pre-activation review (parent linkage)

### Parent acceptance criteria this slice closes outright

None. Both criteria addressed by #15 (command-builder shell-escape spec,
parser mutation recording) are already closed. The remaining open parser
criterion ("every parser has a unit test") is multi-shot — only fully
closed once all six parsers have specs.

### Parent acceptance criteria this slice partially advances

- "Every output parser introduced or extracted by the deepening has at
  least one passing unit test under `tests/utils/obsidian_cli/`,
  exercised by `./tests/run`." — **2 of 6 parsers covered** after
  closure (`search_context` from #15 + `paths` from this slice). Four
  remain: `tasks_verbose`, `unresolved_verbose`, `backlinks_json`,
  `extract_bookmark_note_path`.

### Parent acceptance criteria this slice maintains (does not regress)

- `./tests/run` exits 0 on the whole suite.
- `PATH=...` test suite green with `obsidian` absent.
- `git diff` against `lua/config/commands.lua` empty.
- No reaching into local functions or monkey-patching internals.

### Parent flags this slice resolves or updates

- **Backlinks-parser flag:** unchanged. Stays active for the backlinks
  slice.
- **Bookmark-parser flag:** unchanged. Stays active and the
  pre-document step is still required for that slice.

No new flags expected. `parsers.paths` is the simplest of the six
parsers (single transformation, two skip filters); if a nuance surfaces
in implementation, record it as a flag in this sub-issue's AAR.

## Suggested GitHub issue title

`feature: parser-pass slice — paths parser (orphans + deadends)`

Alternative shorter forms:

- `feature: paths parser specs (orphans + deadends)`
- `test: paths parser + static command builders`
