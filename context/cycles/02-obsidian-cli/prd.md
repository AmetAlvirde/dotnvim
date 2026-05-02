# PRD — Deepen `utils.obsidian_cli`

## Focus

Reshape `lua/utils/obsidian_cli.lua` into four named layers — command builder,
shell adapter, output parser, presenter — so that the parsing and presentation
logic for every Obsidian CLI subcommand can be unit-tested without invoking
the real `obsidian` binary or running a live editing session.

## Intentions

1. Establish the layered "shell-bound utility module" pattern in this
   configuration. `obsidian_cli` is the first deepened module of its kind;
   future cycles deepening other shell-bound or editor-bound utility modules
   should be able to follow this shape rather than relitigating it.
2. Remove the harness-blocked-by-shape gap that the cycle 01 AAR surfaced for
   this specific module — every change to `obsidian_cli.lua` from this cycle
   forward should be expected to ship with tests, and the module's shape
   should not be the reason it can't.
3. Lower the cost of adding a new Obsidian CLI subcommand wrapper from
   "duplicate the four-step pipeline open-coded in 14 places" to "compose the
   existing four layers, write one new parser, write its unit test."

## Goals

1. The module is split into the four named layers — **command builder**,
   **shell adapter**, **output parser**, **presenter** — each with a public
   interface that another layer (or a test) can call without reaching into
   internal locals.
2. The shell adapter is the only layer that invokes any shell-execution call
   (`vim.fn.systemlist`, `os.execute`, `io.popen`, equivalents). All other
   layers are free of shell side effects.
3. The shell adapter exposes a seam — a default implementation plus an
   injection mechanism — so tests can substitute a fake without
   monkey-patching globals or reaching into internals.
4. Every public `M.*` function on `obsidian_cli` retains its name, argument
   shape, and happy-path behavior. The 14 leaf functions become short
   compositions of the four layers; their external contract does not change.
5. Every output parser introduced or extracted by the deepening has at least
   one unit test against a captured sample of real `obsidian` CLI output,
   exercised by `./tests/run`.
6. At least one unit test covers the command builder for a nontrivial
   subcommand — one whose arguments require shell-escaping (e.g.
   `search:context query=...`).
7. After the refactor, `./tests/run` exits 0 on the whole suite, including
   the cycle 01 `wordcount_spec.lua` and all newly added specs.
8. No edits to `lua/config/commands.lua` are required for the deepening to
   close. The user commands continue to load and dispatch through the
   unchanged `M.*` surface.

## Non-goals

1. Refactoring `lua/config/commands.lua`. Its `pcall(require, ...)`
   boilerplate is tracked in `context/refactor-backlog.md` for a future
   cycle.
2. Reshaping `utils.wordcount.buf_line_range_wordcount`. Tracked in
   `context/refactor-backlog.md`.
3. Integration tests that drive the real `obsidian` CLI. Unit tests against
   captured outputs only — the test suite must pass with `obsidian` absent
   from `$PATH`.
4. Tests that drive a full live Neovim editing session for presenter
   behavior. If the presenter cannot be tested as a pure transformation, the
   gap is recorded as a Flag for a future cycle, not closed by writing a UI
   integration test here.
5. Renaming or restructuring the user-facing access surface — no change to
   `:ObsCLI*` command names or their argument shapes.
6. Adding new `obsidian` subcommand wrappers. Only the existing 14 leaf
   functions are in scope.
7. CI integration. Local-only entry point, same as cycle 01.

## User stories

1. As a maintainer fixing a parser regression on a malformed
   `obsidian unresolved verbose` line, I want the parser to be a pure
   function from `lines → items` so that I can write a failing unit test
   from a captured CLI sample before touching code.
2. As a maintainer adding a new Obsidian CLI subcommand wrapper, I want to
   compose the existing four layers rather than copy a 70-line block, so
   that adding a wrapper is a parser-and-leaf-composition change, not a
   pipeline duplication.
3. As a maintainer auditing what in this configuration touches the shell, I
   want exactly one named place in the `obsidian_cli` module where shell
   execution happens, so that I can grep the codebase for the seam without
   scanning 815 lines.
4. As a maintainer running the test suite headlessly, I want every output
   parser to be exercised by at least one unit test against a captured
   sample, so that a CLI-format-driven parser regression cannot reach the
   configuration silently.
5. As a maintainer of `lua/config/commands.lua`, I want this deepening to
   leave my user-command wrappers untouched, so that the cycle does not
   require coordinated edits across files outside its scope.

## Constraints and assumptions

1. Runtime is Neovim 0.11.0+ (per `product.md`).
2. The `obsidian` CLI is an external tool whose output formats may drift
   between releases. The deepening cannot assume a fixed CLI version — pure
   parsers are the *reason* this matters: future format updates become
   test-first parser changes rather than scattered edits.
3. `obsidian_cli.lua` is currently the sole consumer of
   `lua/config/vaults.lua` (`VAULT_ROOTS`). The deepening preserves that
   dependency direction; `vaults.lua` does not depend on anything introduced
   by this cycle.
4. `mini.test` from cycle 01 is the test runner. No new test tooling is
   introduced.
5. No new plugin dependencies. The deepening is internal to
   `lua/utils/obsidian_cli` (whether one file or a directory of siblings is
   an open question below).
6. Tests run without network access and without a live `obsidian` process.
7. The `M.*` public surface is not free to change. Each existing public
   function keeps its name, argument shape, and happy-path behavior.

## Success metrics

These are architectural compliance checks — binary, verifiable.

1. After the refactor, `grep -rn 'systemlist\|os\.execute\|io\.popen'` over
   the `obsidian_cli` source returns exactly one match — the shell adapter
   implementation.
2. Every one of the 14 public `M.*` functions on `obsidian_cli` is still
   exported with the same name and the same argument shape as before the
   refactor.
3. Every output parser introduced by the deepening has at least one passing
   unit test exercised by `./tests/run`. The test directory layout follows
   cycle 01's mirror convention (`tests/utils/...`).
4. For at least one parser, a unit test fails when the parser is
   temporarily broken and passes when reverted — verifying the test
   actually exercises the layer rather than passing trivially.
5. `./tests/run` exits 0 on the whole suite after the refactor.
6. `lua/config/commands.lua` is unchanged in this cycle (`git diff` against
   the cycle's base shows no edits to that file).
7. The test suite passes with `obsidian` removed from `$PATH` — confirmable
   by running `PATH=/usr/bin:/bin ./tests/run` (or equivalent) and getting
   exit 0.

## Success signals

1. The next refactor cycle that touches a shell-bound utility module can
   write "follow the `obsidian_cli` pattern" without elaborating, and a
   reader will know what that means.
2. Adding a new `obsidian` subcommand wrapper after this cycle is a
   copy-edit of an existing leaf composition plus one new parser unit
   test — no pipeline boilerplate reproduced from memory.
3. A future malformed-CLI-output bug report can be reproduced with a
   captured sample line and a one-line failing test, before any fix is
   written.

## Open questions

### 1. Module structure — RESOLVED → submodule directory

`lua/utils/obsidian_cli/init.lua` (the leaf-composition surface, the
`M.*` table) plus siblings `command.lua`, `shell.lua`, `parsers.lua`,
`presenter.lua`.

Reasoning:

- `lua/config/commands.lua` already does `require("utils.obsidian_cli")`.
  Lua resolves that to `init.lua` automatically, so goal #4 (M.\* surface
  preserved) and the "no edits to `commands.lua`" constraint are
  satisfied at the call site with zero churn.
- Single-file (option a) fails goal #1 in spirit: layer boundaries
  become visual rather than structural, and parser tests still have to
  require the parent module and reach into a sub-table — the same shape
  that motivated the deepening.
- Sibling modules (option b) work mechanically but the `obsidian_cli_*`
  prefix is a directory pretending to be flat; it doubles `lua/utils/`
  with prefixed siblings. The submodule directory gets the same
  module-system enforcement without that namespace pollution.
- Submodule directory is the standard Neovim/Lua pattern (telescope,
  lazy, mini itself). The "introduces a new directory pattern" con is
  mild — patterns get introduced when there is a load-bearing need, and
  this is the need.

Trade-offs preserved here for the AAR's record:

- **(a) Single file**: keep `lua/utils/obsidian_cli.lua` as one file
  with the four layers as named local sections plus their own internal
  export tables. Rejected — layer boundaries become visual, tests still
  reach into a sub-table on the parent module.
- **(b) Sibling modules**: split into `lua/utils/obsidian_cli_command.lua`,
  `lua/utils/obsidian_cli_shell.lua`, `lua/utils/obsidian_cli_parsers.lua`,
  `lua/utils/obsidian_cli_presenter.lua`, plus the original
  `lua/utils/obsidian_cli.lua` as the leaf-composition surface.
  Rejected — pollutes the flat `lua/utils/` namespace and reads as a
  directory pretending to be flat.
- **(c) Submodule directory**: `lua/utils/obsidian_cli/init.lua` plus
  `command.lua`, `shell.lua`, `parsers.lua`, `presenter.lua`.
  Accepted.

ADR-0003 candidate, but defer until at least the first sub-issue closes
against this layout — see open question #4. Premature ADRs codify
guesses.

### 2. Shell adapter injection mechanism — RESOLVED → module-level setter on `shell.lua`, used sparingly; child Neovim reserved for editor-state tests

`shell.lua` exposes `set_runner(fn)` (and a matching `reset_runner()`)
with a default that wraps `vim.fn.systemlist`. Tests that exercise the
leaf-composition functions end-to-end with a captured CLI sample swap
the runner inside `pre_case` / restore in `post_case` (or via
`mini.test.finally`). Pure parser tests and command-builder tests
require their modules directly and need no seam at all. Tests that
genuinely need editor-state isolation (presenter touching `setqflist`,
scratch-buffer creation) use `mini.test.new_child_neovim`.

Reasoning:

- Most architectural-compliance value comes from testing parsers and
  the command builder as pure modules — no seam needed. This keeps the
  upvalue surface small and the smell contained.
- The seam only matters for leaf-composition tests that exercise an
  `M.tasks_to_quickfix`-shaped function with a fake CLI response. The
  module-level setter is the simplest mechanism that respects goal #4
  (no signature changes to `M.*`).
- Per-function parameter (option b) leaks a test concern into the
  production signature. Rejected.
- Child Neovim is correct but heavy; reserve for the narrow set of
  presenter tests that need real editor-state isolation. Don't pay
  process-spawn cost for pure parser tests.

Trade-offs preserved here for the AAR's record:

- **(a) Module-level setter on `shell.lua`**: `set_runner(impl)` plus a
  default. Pro: simple, no `M.*` signature changes, restorable in
  mini.test hooks. Con: module-mutable state — tests must restore.
  Accepted.
- **(b) Per-function parameter**: pass an optional adapter into each
  public function's options table. Pro: pure DI. Con: signature change
  on `M.*` — violates goal #4 unless strictly opt-in, and even opt-in
  it leaks a test concern into production. Rejected.
- **(c) `mini.test` child Neovim** as the only mechanism: spawn a
  fresh Neovim per test. Pro: real isolation. Con: heavy per-test cost,
  still requires the adapter to be swappable inside the child.
  Rejected as primary mechanism — accepted as the mechanism for
  presenter / editor-state tests only.

### 3. Presenter testing scope — `RESOLVE THROUGH IMPLEMENTATION`

The presenter touches `vim.fn.setqflist`, `vim.api.nvim_create_buf`, and
similar editor APIs. Whether to test the presenter as a pure transformation
`(parsed_items) → quickfix_payload` and stop at the boundary, or to drive
a real `setqflist` and assert via `getqflist` in a child Neovim, depends on
how cleanly (a) factors when we actually extract the layer. Decide during
implementation; if the boundary doesn't factor cleanly, record a Flag and
test what is testable.

### 4. ADR-0003 for the four-layer pattern? — `RESOLVE THROUGH IMPLEMENTATION`

The shape "command builder → shell adapter → output parser → presenter" is
generalizable to any shell-bound utility module in this configuration —
plausibly the deepening shape for whatever future cycles tackle from
`refactor-backlog.md`. If the deepening lands cleanly and the pattern
proves durable across at least one full sub-issue, an ADR scoping it as
the convention for shell-bound utility modules is warranted. Defer until
the first sub-issue closes — premature ADRs codify guesses.

### 5. Layer naming — RESOLVED → command builder, shell adapter, output parser, presenter

Resolved during the pitch. "Shell adapter" was preferred over "runner" to
avoid collision with the test-runner concept already established in cycle
01 (mini.test). Trade-off analysis preserved here for the AAR's record:

- "Runner" — short, generic, but already overloaded in this repo.
  Rejected.
- "Shell adapter" — names the seam role explicitly (adapter pattern, used
  in the process spec when discussing test seams) and reads naturally on
  the test side as "fake shell adapter." Accepted.
- "CLI runner" — disambiguates from the test runner but is redundant with
  the module name (`obsidian_cli`). Rejected as awkward.
- "Executor" — too generic, no role signal. Rejected.

## Domain validation pass

Walking the PRD for terms a domain expert (a user of this Neovim
configuration) would use:

- **vault**, **vault root**, **vault-relative path** — Obsidian-domain
  vocabulary used throughout the PRD when describing what
  `obsidian_cli.lua` mediates. The author would use these terms when
  describing the configuration's behavior to another developer. Added to
  `ubiquitous-language.md`.
- **Obsidian CLI** — the external tool this module wraps. The author would
  use this term when describing why the module exists. Added to
  `ubiquitous-language.md`.
- **command builder**, **shell adapter**, **output parser**, **presenter**
  — pattern-language for the deepening, not domain terms. They describe
  module architecture, not the configuration's user-facing behavior. Per
  glossary policy ("skip module names, class names, and general
  programming concepts unless they carry domain-specific meaning"), they
  do not enter the glossary. If the four-layer pattern proves durable
  across cycles, ADR-0003 captures it.
- **subcommand**, **leaf function**, **pipeline**, **layer**, **seam**,
  **fake** — general programming/architecture vocabulary. Excluded.
- **quickfix**, **scratch buffer** — Neovim-internal vocabulary, excluded
  per the same general-concepts rule.

Exit condition: every domain term in the PRD is defined in
`ubiquitous-language.md`.
