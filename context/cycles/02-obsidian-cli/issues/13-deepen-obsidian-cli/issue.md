# Parent Issue — Deepen `utils.obsidian_cli`

GitHub issue: #13. Sole parent of cycle `02-obsidian-cli`. Translates
`sub-prd.md` into a trackable technical unit. The two artifacts are
complementary — `sub-prd.md` records product-level intent (user
stories, scope, dependencies); this file records the technical
contract (acceptance criteria, implementation approach, flags).

## Acceptance criteria

- [ ] `lua/utils/obsidian_cli/init.lua` exists and exports the same 14
      `M.*` functions that the pre-cycle `lua/utils/obsidian_cli.lua`
      exposed, with the same names and the same argument shapes.
      Verified by `git diff` against the cycle base showing
      preserved-export parity, and by `lua/config/commands.lua`
      loading without edits.
- [ ] The four sibling modules `command.lua`, `shell.lua`,
      `parsers.lua`, `presenter.lua` exist under
      `lua/utils/obsidian_cli/` and are independently `require`-able.
- [ ] `grep -rn 'systemlist\|os\.execute\|io\.popen' lua/utils/obsidian_cli/`
      returns exactly one match, located inside `shell.lua`.
- [ ] `shell.lua` exposes `set_runner(fn)` and `reset_runner()`. The
      default runner wraps `vim.fn.systemlist` and is in effect on
      module load. No `M.*` function on `init.lua` accepts a runner
      parameter.
- [x] Every output parser introduced or extracted by the deepening has
  at least one passing unit test under `tests/utils/obsidian_cli/`,
  exercised by `./tests/run`. The test directory layout mirrors
  `lua/`. *(Progress as of #20: 6 of 6 parsers have dedicated specs —
  `search_context` [#15], `paths` [#16], `tasks_verbose` [#17],
  `unresolved_verbose` [#18], `backlinks_json` [#19],
  `extract_bookmark_note_path` [#20].)*
- [x] At least one parser has a mutation test: temporarily breaking
      the parser causes its spec to fail; reverting causes it to
      pass. Recorded in the closing sub-issue's AAR. *(#15
      `15-search-context-builder-parser/aar.md`.)*
- [x] At least one command-builder spec covers a subcommand whose
      arguments require shell-escaping — `search:context query=...` is
      the canonical case. *(`tests/utils/obsidian_cli/command_spec.lua`.)*
- [x] `./tests/run` exits 0 on the whole suite — including
      `tests/utils/wordcount_spec.lua` from cycle 01.
- [x] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      test suite runs to green with `obsidian` absent from `$PATH`).
- [ ] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is
      empty.
- [x] No reaching into local functions or monkey-patching internals
      anywhere in the new specs. Carry-forward acceptance criterion
      from cycle 01, still binding.
- [ ] Decision on ADR-0003 (the four-layer-pattern ADR) recorded —
      either authored at `context/adr/0003-<slug>.md` with INDEX
      updated, or explicitly deferred-with-reason in this issue's
      closing AAR.

## Implementation approach

### Layout (resolved — PRD open question #1)

Submodule directory `lua/utils/obsidian_cli/` with:

- `init.lua` — leaf compositions, the `M.*` table.
  `lua/config/commands.lua` calls `require("utils.obsidian_cli")` and
  Lua resolves to `init.lua`. No edits at the call site.
- `command.lua` — pure command-string builders. No shell calls, no
  Vim API calls beyond `vim.fn.shellescape`.
- `shell.lua` — the only module that invokes `vim.fn.systemlist` (or
  any equivalent). Exposes `set_runner(fn)` / `reset_runner()` plus
  the default runner.
- `parsers.lua` — pure transformations from CLI lines/text to typed
  Lua tables. No shell, no Vim API.
- `presenter.lua` — quickfix and scratch-buffer presentation. Touches
  `vim.fn.setqflist`, `vim.api.nvim_create_buf`, etc. Tested as a
  pure transformation where it factors; via `mini.test.new_child_neovim`
  where it does not. Decision recorded per sub-issue.

### Shell-adapter seam (resolved — PRD open question #2)

`shell.lua` exposes a module-level setter — `set_runner(fn)` —
defaulting to a wrapper over `vim.fn.systemlist`. Tests that exercise
leaf compositions end-to-end with a captured CLI sample swap the
runner inside `pre_case` and restore inside `post_case` (or via
`mini.test.finally`). Pure parser tests and command-builder tests
require their modules directly and use no seam at all. Editor-state
tests (presenter touching `setqflist`, scratch-buffer creation) use
`mini.test.new_child_neovim`. The `M.*` signatures on `init.lua`
never accept a runner parameter.

### Sequencing

Per the cycle 01 process spec, work proceeds: Stage 1 tracer →
Stages 2–3 incremental TDD → Stage 4 deepen. For this parent issue
that maps to:

- **First sub-issue (#14):** layer skeleton + tracer. Move the
  existing 815-line file into `lua/utils/obsidian_cli/` split across
  the four siblings; `init.lua` re-exposes the 14 `M.*` functions.
  Smoke spec: `obsidian_cli` loads, all 14 names are present, `:lua=`
  on each leaf returns its expected error envelope when invoked
  outside a vault. No new parser tests yet — the goal is parity, not
  coverage.

- **Subsequent sub-issues (#15+):** parser-by-parser pass. Each sub-issue
  picks one parser family, captures sample CLI output as a test
  fixture, adds the spec, refactors the parser to be unit-testable
  if it is not already, lands green. Rough groupings (final
  sequencing decided per sub-issue, informed by prior AARs):

  - `paths_to_quickfix` family — orphans, deadends.
  - `tasks_verbose_to_items` — the grouped-by-file format.
  - unresolved-verbose tab-separated parser.
  - `parse_path_line_text` — search:context, the shell-escape case.
  - `try_decode_json_object` + `backlinks_json_to_rows` — backlinks
    JSON, schema-tolerant.
  - `extract_bookmark_note_path` — bookmarks TSV.
  - Presenter testability assessment — first presenter spec, or
    a Flag if it does not factor.

  Sub-issue numbering follows ADR-0002 — sequential GitHub issue
  numbers, not cycle-local numbers.

- **Final sub-issue:** ADR-0003 decision. Either author the
  four-layer-pattern ADR (if it has proven durable across the
  preceding sub-issues) or record deferral-with-reason in the AAR.

### Constraints binding the implementation

1. The 14 `M.*` exports keep their names and argument shapes. No
   signature changes — this includes opt-in parameters.
2. `lua/config/commands.lua` is not edited in this cycle. Its
   `pcall(require, ...)` boilerplate is on the refactor backlog for a
   future cycle.
3. Tests exercise public interfaces only. No reaching into local
   functions, no monkey-patching globals. The shell-adapter setter is
   the seam; everything else uses pure-module `require`.
4. Test fixtures (captured CLI output samples) live under
   `tests/utils/obsidian_cli/fixtures/` as plain text files. They are
   read by specs, not generated.
5. The test suite runs to green with `obsidian` absent from `$PATH`.
6. No new plugin dependencies. `mini.test` from cycle 01 is the only
   test tooling.

## Dependencies

- **Cycle 01 closure** — `mini.test` harness in place at `./tests/run`,
  `tests/init.lua` bootstrap with the `os.exit(0)` short-circuit
  preserved. Already closed (parent `01-harness-foundation`).
- **ADR-0001** — `mini.test` as the test runner. Accepted.
- **ADR-0002** — issue folder numbers track GitHub issue numbers.
  Accepted. Drives the `13-deepen-obsidian-cli` slug and the #14+
  numbering for sub-issues.
- No dependency on any other cycle 02 parent — this is the sole
  parent of the cycle.

## Flags

- [ ] [#14 AAR → backlinks-parser sub-issue (#15+)] *(partially resolved by #19)*

  **Pure-parser sub-requirement — closed by #19.** `parsers.backlinks_json`
  returns `nil` on JSON-parse-failure and `{}` on parse-success-but-no-rows.
  Both branches are now exercised by dedicated named cases in
  `tests/utils/obsidian_cli/parsers_spec.lua`. See `19-…/aar.md`.

  **Integration-path sub-requirement — still open.** The two distinct
  user-facing messages in `init.lua` ("Could not parse backlinks JSON…" vs
  "No backlinks parsed from JSON…") require the shell-adapter seam plus
  quickfix / scratch-buffer state assertions, or a child-Neovim spec.
  Deferred to a future presenter / shell-seam slice.

  Files to review:
  - `lua/utils/obsidian_cli/init.lua` (`M.backlinks_counts_to_quickfix`)
  - `context/cycles/02-obsidian-cli/issues/13-deepen-obsidian-cli/19-backlinks-json-builder-parser/aar.md`

- [x] [#14 AAR → bookmark-parser sub-issue (#15+)] **Resolved by #20.**

  Option B (DI resolver seam) was selected and documented in the sub-issue before
  implementation. `parsers.set_resolver(fn)` / `parsers.reset_resolver()` added
  to `parsers.lua`. Tests stub the resolver via `pre_case`/`post_case`; no disk
  access in the new cases. 14 named specs cover all observable behaviors of
  `extract_bookmark_note_path`. See `20-bookmark-parser-resolver-seam/aar.md`.
