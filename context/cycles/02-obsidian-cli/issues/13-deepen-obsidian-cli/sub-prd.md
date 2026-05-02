# Sub-PRD — Deepen `utils.obsidian_cli`

> Translated to `issue.md`. This sub-PRD records the product-level
> intent — user stories and dependencies. Update `issue.md` for ongoing
> technical work. Update this file only if the underlying user stories
> themselves change.

Sole sub-PRD of cycle `02-obsidian-cli`. Carries all five user stories
from the cycle PRD — they share the same system boundary
(`lua/utils/obsidian_cli.lua`) and cannot be reasoned about
independently of one another. Splitting was considered and rejected:
the parser pass and the layer extraction look separable in narrative,
but the parser pass cannot be specified without the layer split, and
the layer split has no testable acceptance signal without the parser
pass. The natural sequencing lives at the sub-issue level (Phase 5),
not here.

## Scope

Reshape `lua/utils/obsidian_cli.lua` (currently one 815-line file
exposing 14 leaf functions) into the four layers — **command builder**,
**shell adapter**, **output parser**, **presenter** — under the
submodule directory `lua/utils/obsidian_cli/` (resolved in PRD open
question #1). The shell adapter exposes a `set_runner(fn)` seam
(resolved in PRD open question #2) so parsers and command-builder
logic can be unit-tested without a live `obsidian` process or a live
editing session. The 14 public `M.*` functions retain their names,
argument shapes, and happy-path behavior; `lua/config/commands.lua` is
not edited.

## User stories

1. **Parser-as-pure-function for regression-fix workflow.** As a
   maintainer fixing a parser regression on a malformed
   `obsidian unresolved verbose` line, I want the parser to be a pure
   function from `lines → items` so that I can write a failing unit
   test from a captured CLI sample before touching code.

2. **Compose, don't duplicate, when adding a wrapper.** As a
   maintainer adding a new Obsidian CLI subcommand wrapper, I want to
   compose the existing four layers rather than copy a 70-line block,
   so that adding a wrapper is a parser-and-leaf-composition change,
   not a pipeline duplication.

3. **One named place that touches the shell.** As a maintainer
   auditing what in this configuration touches the shell, I want
   exactly one named place in the `obsidian_cli` module where shell
   execution happens, so that I can grep the codebase for the seam
   without scanning 815 lines.

4. **Every parser exercised by a headless unit test.** As a maintainer
   running the test suite headlessly, I want every output parser to be
   exercised by at least one unit test against a captured sample, so
   that a CLI-format-driven parser regression cannot reach the
   configuration silently.

5. **No coordinated edits to the user-command surface.** As a
   maintainer of `lua/config/commands.lua`, I want this deepening to
   leave my user-command wrappers untouched, so that the cycle does
   not require coordinated edits across files outside its scope.

## Encounter statements

None. The cycle PRD does not carry encounter statements. This is a
maintainer-internal architectural deepening — the encounter is the
test-writing experience and the grep-for-the-seam experience, both
already captured by the user stories above.

## Dependencies

None on other sub-PRDs — this is the sole sub-PRD of cycle 02.

External dependencies (carried from the cycle PRD's constraints, not
sub-PRD dependencies):

- `mini.test` runner from cycle 01 (ADR-0001) — assumed in place,
  invoked via `./tests/run`.
- `lua/config/vaults.lua` (`VAULT_ROOTS`) — `obsidian_cli` is its sole
  consumer; the deepening preserves that direction.
- ADR-0002 — this parent issue is GitHub #13, hence the folder slug
  `13-deepen-obsidian-cli`.

## Resolved decisions that bind this sub-PRD's scope

- **Module structure (PRD #1):** submodule directory
  `lua/utils/obsidian_cli/` with `init.lua` (leaf surface),
  `command.lua`, `shell.lua`, `parsers.lua`, `presenter.lua`.
- **Shell adapter injection (PRD #2):** `shell.lua` exposes
  `set_runner(fn)` / `reset_runner()` with a default wrapping
  `vim.fn.systemlist`. Pure parser and command-builder tests bypass
  the seam entirely. `mini.test.new_child_neovim` reserved for
  presenter / editor-state tests only.
- **Layer naming (PRD #5):** command builder, shell adapter, output
  parser, presenter. "Shell adapter" was chosen over "runner" to avoid
  collision with the cycle 01 test runner.

## Resolve-through-implementation items carried forward

- **Presenter testing scope (PRD #3):** decide during sub-issue
  implementation whether the presenter factors as a pure
  `(parsed_items) → quickfix_payload` transformation, or whether it
  needs a child-Neovim test. If it does not factor cleanly, record a
  Flag and test what is testable.
- **ADR-0003 for the four-layer pattern (PRD #4):** defer until at
  least the first sub-issue closes against the layout. Premature ADRs
  codify guesses.

## Out of scope (carried from cycle PRD)

- Refactoring `lua/config/commands.lua` `pcall(require, ...)`
  boilerplate — tracked in `context/refactor-backlog.md`.
- Reshaping `utils.wordcount.buf_line_range_wordcount` — tracked in
  `context/refactor-backlog.md`.
- Adding new Obsidian CLI subcommand wrappers — only the existing 14
  leaf functions are in scope.
- Renaming or restructuring `:ObsCLI*` user commands.
- Integration tests against the real `obsidian` binary — test suite
  must pass with `obsidian` absent from `$PATH`.
- Live-Neovim editing-session UI tests for presenter behavior.
- CI integration — local-only, same as cycle 01.

## Domain validation pass

No new domain terms are introduced by this sub-PRD beyond those
already added during the PRD's domain validation pass (vault, vault
root, vault-relative path, Obsidian CLI). The four layer names
(command builder, shell adapter, output parser, presenter) are
pattern-language for module architecture, not domain vocabulary —
excluded from the glossary per its policy on general programming
concepts.
