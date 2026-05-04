# Sub-issue — search:context builder + parser

GitHub issue: #15 (confirmed). Second sub-issue of parent #13. The first parser-pass slice
after the #14 layer-skeleton tracer. Lands the canonical
shell-escape command-builder spec, the first pure-parser unit test
under `tests/utils/obsidian_cli/`, and the first mutation-test
recording — three parent acceptance criteria advanced (one closed
outright, one fully satisfied, one partially advanced) by a single
narrowly scoped slice.

## Description

Add unit tests for two leaf modules already in place from #14:

- `command.search_context(query)` — exercise the shell-escape behavior
  on inputs that contain spaces, single quotes, and shell metacharacters.
  This is the canonical command-builder spec named in the parent issue's
  acceptance criteria ("at least one command-builder spec covers a
  subcommand whose arguments require shell-escaping — `search:context
  query=...` is the canonical case").
- `parsers.search_context(lines)` — exercise the
  `path:line:text` → quickfix-item transformation against a captured CLI
  fixture. Cover the three line shapes `parse_path_line_text` accepts
  (colon-after-line, space-after-line, TSV) plus skip-empty and
  skip-malformed.

Record one **mutation test** during implementation: temporarily break
`parsers.search_context` (for example, return `items` early before the
loop runs), confirm the spec turns red, revert, confirm green. The
mutation is not a committed spec — it is an entry in this sub-issue's
AAR.

No production code changes are required. Both `command.search_context`
and `parsers.search_context` already exist from #14; this slice adds
their tests and the fixture file. If the tests reveal a defect in the
existing implementation, fix-with-test stays in scope; speculative
parser changes do not.

## Dependency classification

| Dependency                                           | Category                  | Testing strategy                                                                                                                          |
| ---------------------------------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `obsidian` CLI binary                                | True external (platform)  | Not invoked. Specs read fixture text from disk; `command.search_context` builds a string and never executes it.                            |
| `vim.fn.shellescape`                                 | In-process (Neovim API)   | Called by `command.search_context`. Tests assert against its real output — no stub. Behavior is stable across Neovim versions for the inputs we test. |
| `vim.fn.systemlist`                                  | In-process (Neovim API)   | Not exercised by this slice. The shell seam stays untouched.                                                                              |
| `lua/config/vaults.lua` (`VAULT_ROOTS`)              | In-process                | Loaded transitively when `parsers.lua` is required. No test substitution — this is the same posture as #14.                                |
| `mini.test`                                          | In-process                | Loaded via cycle 01's harness. Spec runs through `./tests/run`.                                                                            |
| Captured CLI fixture (`search_context.txt`)          | Test artifact             | Plain text under `tests/utils/obsidian_cli/fixtures/`, read by the spec via `io.open`. Documented as captured-by-hand in the AAR.          |

No new seams introduced. The shell-adapter seam from #14 is **not**
exercised — both modules under test are pure with respect to shell
execution. The `vim.fn.shellescape` call inside the command-builder is
treated as a deterministic in-process helper, not a seam.

## Interface design / scope

The interfaces under test are already finalized in #14. This slice's
"interface design" is the **test surface** — what the spec asserts and
what it does not.

### `command.search_context` test surface

The spec requires the public `command` module and calls
`command.search_context(query)` directly. No reaching into locals; the
private `shellescape` alias inside `command.lua` is not referenced.

Assertions cover:

1. **Plain ASCII query.** `command.search_context("hello")` →
   `obsidian search:context query='hello'` (or whatever
   `vim.fn.shellescape("hello")` returns on the host platform — the
   spec composes the expected string from `vim.fn.shellescape("hello")`
   to remain platform-tolerant; what is asserted is the surrounding
   shape `^obsidian search:context query=` followed by the escaped
   argument).
2. **Query with spaces.** `command.search_context("two words")`. Spec
   asserts the escaped fragment appears verbatim after `query=` and
   that the result, when passed back through a shell tokenizer
   (`vim.fn.split` with shellescape semantics is overkill — instead
   the spec checks the raw `string.find` for the expected escaped
   form), preserves the multi-word argument as a single token.
3. **Query with a single quote.** `command.search_context("it's")`.
   This is the load-bearing escape case — POSIX-style shellescape
   emits `'it'\''s'`. Spec asserts the exact escaped substring after
   `query=`.
4. **Query with shell metacharacters.** `command.search_context("a; rm -rf b")`.
   Spec asserts the dangerous tokens are quoted, not interpolated —
   concretely, that the entire payload appears inside a single pair of
   single quotes (with `\''` escapes), and that bare `;` does not
   appear unquoted in the result.
5. **Empty string.** `command.search_context("")`. Behavior is what
   `vim.fn.shellescape("")` produces (typically `''`) — the spec
   documents the produced shape rather than asserting "must reject."
   Reason: the leaf `M.search_context_to_quickfix` in `init.lua` is
   the layer responsible for rejecting empty queries (it does, with
   `"Query is required."`); the builder is correct to be permissive.

The spec composes expected values from `vim.fn.shellescape` rather
than hardcoding shell-quoted strings. This keeps it portable across
shells while still exercising the escape logic — the mutation that
matters (replacing `shellescape(query)` with bare `query`) breaks the
expected-string composition just as cleanly as a hardcoded literal
would.

### `parsers.search_context` test surface

Spec requires `utils.obsidian_cli.parsers` and calls
`parsers.search_context(lines)` against fixture-derived inputs.

Assertions cover:

1. **Colon-after-line shape.** Lines like `notes/foo.md:42: matched text`
   produce items with `filename = "notes/foo.md"`, `lnum = 42`,
   `text = "matched text"`, `col = 1`.
2. **Space-after-line shape.** Lines like `notes/bar.md:7  prefix matched`
   produce equivalent items (the parser's second regex branch).
3. **TSV-ish shape.** A line like `notes/baz.md\t13\trest of text`
   parses through the TSV branch.
4. **Empty-line skip.** Empty strings and whitespace-only lines yield
   no items.
5. **Malformed-line skip.** A line that contains no path:line shape at
   all (e.g. `total: 12`) produces no item.
6. **Mixed-input fixture.** A multi-line fixture combining all three
   shapes plus blanks plus malformed produces exactly the expected
   item count and item values, end-to-end.

The fixture lives at
`tests/utils/obsidian_cli/fixtures/search_context.txt` and is read at
spec time. The spec splits the file by `\n` and passes the resulting
list to `parsers.search_context`. The fixture is a representative
hand-curated sample, not real CLI output captured in this session —
the AAR records this and the rationale (the parser shape is fully
specified by the three branches in `parse_path_line_text`; capturing
one literal real-world run would not exercise the TSV branch unless we
got lucky, and would not be reproducible without `obsidian` in `$PATH`,
which violates the parent's constraint).

### Mutation-test recording

During implementation, run the mutation once and record in the AAR.
Suggested mutation: in `parsers.search_context`, change
`if parsed and parsed.path and parsed.lnum then` to
`if false then`. The fixture-driven spec turns red. Revert. Spec
returns to green. Record the diff and the failure output snippet in
the AAR. Not a committed spec.

## Acceptance criteria

- [x] `tests/utils/obsidian_cli/command_spec.lua` exists, requires
      `utils.obsidian_cli.command`, and exercises
      `command.search_context` against five inputs covering ASCII,
      spaces, single quotes, shell metacharacters, and the empty
      string. Each assertion composes its expected value from
      `vim.fn.shellescape` rather than hardcoding shell-quoted
      strings.
- [x] `tests/utils/obsidian_cli/parsers_spec.lua` exists, requires
      `utils.obsidian_cli.parsers`, and exercises
      `parsers.search_context` against the three accepted line shapes,
      plus empty-line skip, plus malformed-line skip, plus a
      multi-shape fixture-driven mixed input.
- [x] `tests/utils/obsidian_cli/fixtures/search_context.txt` exists,
      contains a hand-curated mixed-shape sample, and is read by the
      mixed-input parser spec at runtime.
- [x] `./tests/run` exits 0 on the whole suite — the new specs plus
      the #14 tracer plus cycle 01's `wordcount_spec.lua`.
- [x] `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exits 0. No
      shell call to `obsidian` happens during the new specs.
- [x] No reaching into local functions or monkey-patching globals in
      the new specs. Both private locals — `shellescape` in
      `command.lua` and `parse_path_line_text` in `parsers.lua` — are
      exercised only through their public callers.
- [x] Mutation-test recording: AAR documents the mutation applied,
      the failing test output, and confirmation that reverting
      restored green. The mutation itself is not committed.
- [x] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is
      empty (carry-forward from parent — this slice does not edit the
      consumer).
- [x] `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` shows
      no changes other than fixes-with-test (if any). Speculative
      parser or builder changes are out of scope.

## Proposed tests

| Title                                                                          | What it verifies                                                                                                       |
| ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `command.search_context` builds plain ASCII queries                             | `obsidian search:context query=` prefix + `shellescape("hello")` suffix.                                                 |
| `command.search_context` escapes spaces                                         | Multi-word query produces a single shell-quoted token after `query=`.                                                  |
| `command.search_context` escapes single quotes                                  | `"it's"` produces the POSIX-quote-escape form. Load-bearing case.                                                       |
| `command.search_context` neutralizes shell metacharacters                       | `"a; rm -rf b"` is fully quoted; bare `;` does not appear in the result.                                                |
| `command.search_context` accepts empty string                                   | Documents observed shape; the leaf in `init.lua` is what rejects empty input.                                            |
| `parsers.search_context` parses `path:line:text` lines                          | Item shape: `{ filename, lnum, col=1, text }`.                                                                          |
| `parsers.search_context` parses `path:line text` lines                          | Second-branch regex.                                                                                                   |
| `parsers.search_context` parses TSV-shaped lines                                | Third-branch fallback.                                                                                                 |
| `parsers.search_context` skips empty lines                                      | Whitespace-only and `""` lines produce no item.                                                                         |
| `parsers.search_context` skips malformed lines                                  | Lines lacking any `path:line` shape produce no item.                                                                    |
| `parsers.search_context` against a mixed-shape fixture                          | End-to-end count and value check from `tests/utils/obsidian_cli/fixtures/search_context.txt`.                            |

A **deliberate-failure / mutation verification** is run once on
`parsers.search_context` during implementation (suggested: replace the
guard with `if false then`, confirm red, revert, confirm green).
Recorded in the AAR. Not a committed spec.

## Affected artifacts

- New: `tests/utils/obsidian_cli/command_spec.lua`
- New: `tests/utils/obsidian_cli/parsers_spec.lua`
- New: `tests/utils/obsidian_cli/fixtures/search_context.txt`
- Unchanged (verified by `git diff`): everything under
  `lua/utils/obsidian_cli/`, `lua/config/commands.lua`,
  `tests/utils/obsidian_cli/init_spec.lua`, `tests/init.lua`,
  `tests/run`, `tests/utils/wordcount_spec.lua`.
- Unchanged: parent `issue.md` (the slice closes parent acceptance
  criteria but does not require parent edits).
- New (closing artifact): `15-search-context-builder-parser/aar.md` —
  records the mutation diff, the captured-failure output, and any
  deviations from this plan.

## Dependencies

- **Sub-issue #14 (closed).** Provides `command.search_context`,
  `parsers.search_context`, the `tests/utils/obsidian_cli/` directory,
  and the layered module shape this slice tests against.
- **ADR-0001** — `mini.test` runner. Accepted.
- **ADR-0002** — folder slug `15-...` tracks GitHub issue number.
  Confirm `#15` at activation; rename folder if the actual issue gets
  a different number.
- No dependency on any other parent or any other cycle.

## Out of scope (deferred to later #15+ slices)

- Parser tests for the other five parsers — `paths`, `tasks_verbose`,
  `unresolved_verbose`, `backlinks_json`, `extract_bookmark_note_path`.
  Each is a separate slice. Parent acceptance criterion "every parser
  has at least one passing unit test" is **partially advanced** by
  this slice, not closed.
- Command-builder tests for the other builders. The parent only
  requires "at least one" command-builder spec covering shell-escaping;
  this slice closes that criterion outright. Future per-leaf builder
  specs are nice-to-have, not required.
- Integration-style coverage of `init.lua`'s `search_context_to_quickfix`
  composition. The leaf calls `presenter.scratch` on no-match and
  `vim.cmd("copen")` on match — testing those requires either the
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

- "At least one command-builder spec covers a subcommand whose
  arguments require shell-escaping — `search:context query=...` is
  the canonical case." — **closed by `command_spec.lua`**.
- "At least one parser has a mutation test: temporarily breaking the
  parser causes its spec to fail; reverting causes it to pass.
  Recorded in the closing sub-issue's AAR." — **closed by the
  mutation recording on `parsers.search_context` in the AAR**.

### Parent acceptance criteria this slice partially advances

- "Every output parser introduced or extracted by the deepening has
  at least one passing unit test under `tests/utils/obsidian_cli/`,
  exercised by `./tests/run`. The test directory layout mirrors
  `lua/`." — **1 of 6 parsers covered** (`search_context`). Five
  parsers remain (`paths`, `tasks_verbose`, `unresolved_verbose`,
  `backlinks_json`, `extract_bookmark_note_path`).

### Parent acceptance criteria this slice maintains (does not regress)

- `./tests/run` exits 0 on the whole suite.
- `PATH=...` test suite green with `obsidian` absent.
- `git diff` against `lua/config/commands.lua` empty.
- No reaching into local functions or monkey-patching internals.

### Parent flags this slice resolves or updates

- **Backlinks-parser flag:** unchanged. Stays active for the
  backlinks slice.
- **Bookmark-parser flag:** unchanged. Stays active and the
  pre-document step is still required for that slice.

No new flags expected. If the mutation-test recording surfaces a
nuance (for example, `parse_path_line_text` having behavior the
spec did not anticipate), record it as a flag in this sub-issue's
AAR for future slices to read.

## Suggested GitHub issue title

`feature: parser-pass slice — search:context builder + parser tests`

Alternative shorter forms if the title bar gets crowded:

- `feature: search:context builder + parser specs`
- `test: search:context shell-escape + parser specs`
