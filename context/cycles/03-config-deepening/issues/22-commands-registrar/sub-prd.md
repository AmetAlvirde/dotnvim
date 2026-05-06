## Sub-PRD — `commands.lua` declarative dispatch (Candidate A)

> Translated to `issue.md`. This sub-PRD records the product-level intent --
> user stories and dependencies. Update `issue.md` for ongoing technical work.
> Update this file only if the underlying user stories themselves change.

First parent issue of cycle `03-config-deepening`, per the resolved
sequencing in the cycle PRD's open question #1
(A → D → B → C). Carries the cycle PRD's Candidate A goal — a
`commands.register(spec)` registrar — and the slice of the cycle's
cross-cutting stories (5 and 6) that lands on `lua/config/commands.lua`.
Splitting was considered and rejected: the registrar interface, the
spec-row reshape of `commands.lua`, and the test pattern for faking
`vim.api.nvim_create_user_command` are the same piece of work and
cannot be specified independently. Natural sequencing lives at the
sub-issue level.

## Scope

Build `commands.register(spec)` — a public, unit-testable registrar that
takes a spec table describing one user command (name, description,
argument shape, the leaf module to require, the leaf function to call
on it, error and info handling) and registers the command via
`vim.api.nvim_create_user_command`. Reshape `lua/config/commands.lua`
into a list of spec rows that each feed the registrar. The per-command
`pcall(require, ...)` → call → `vim.notify` block — currently repeated
across the file's 14 ObsCLI handlers — is gone. The registrar carries
that shape once, behind a tested seam.

The 18 user commands currently defined in `commands.lua` retain their
names, argument shapes, and observable behavior. No command is added,
renamed, or removed. No leaf module is edited — `utils.obsidian_cli`,
`utils.wordcount`, and `colors.solarized` are consumed through their
existing public surfaces.

Candidate F from the cycle PRD (splitting `commands.lua` by domain —
`solarized`, `obsidian_cli`, `wordcount`) is not scoped as a separate
parent issue. It is folded into A's closing sub-issue: if the registrar
makes the file scannable as one declarative list, the split is skipped;
if A's closure surfaces a real reason to split, a closing sub-issue
handles it.

This parent issue establishes the test pattern — faking
`vim.api.nvim_create_user_command` to assert registration shape without
a live editor session — that Candidates B and D inherit when they
extract their own seams.

## User stories

1. **Register one row, not fourteen lines.** As a maintainer adding a
   new ObsCLI command, I want to register it as one row in a spec table,
   so that the cost of adding a command is one line of intent and not
   14 lines of `pcall` / call / `notify` boilerplate. *(Cycle PRD story
   #1, owned wholly by this sub-PRD.)*

2. **Registrar exercised by a headless unit test.** As a maintainer
   running the test suite headlessly, I want the registrar to be
   exercised by at least one unit test against `./tests/run`, so that
   a regression in the registration shape — argument-handling,
   error-envelope, info-notify — cannot reach the configuration
   silently. *(Cycle PRD story #5, scoped here to the registrar
   surface; the other extracted seams are owned by B, C, D.)*

3. **`commands.lua` reads top-to-bottom as a declarative spine.** As a
   maintainer of the wiring files at cycle close, I want
   `lua/config/commands.lua` to read top-to-bottom as a list of
   command-row registrations, so that the file's purpose is visible
   without reading the modules it wires together. *(Cycle PRD story
   #6, scoped here to `commands.lua`; the lualine and autocmds spines
   are owned by B and D.)*

## Encounter statements

None. The cycle PRD does not carry encounter statements. This is a
maintainer-internal architectural deepening — the encounter is the
add-a-command experience and the read-the-wiring-file experience, both
already captured by the user stories above.

## Dependencies

### On other sub-PRDs of cycle 03

None upstream. A is the first parent in the resolved sequencing
(A → D → B → C). A produces the test pattern (faking
`vim.api.nvim_create_user_command` in specs without a live editor) that
B and D inherit. That is a forward dependency from B and D *on* A, not
a dependency of A on anything in this cycle.

### External dependencies (carried from the cycle PRD)

- **Cycle 02 closure** — the 14 `M.*` functions on
  `lua/utils/obsidian_cli/init.lua` keep their names and argument
  shapes. A's spec rows register against that surface; the surface is
  not edited in this cycle.
- **`mini.test` runner from cycle 01 (ADR-0001)** — the test pattern
  for the registrar runs under `./tests/run`. No new test tooling.
- **ADR-0002** — this parent issue is GitHub #22, hence the folder slug
  `22-commands-registrar`. Sub-issues take sequential GitHub numbers.
- **`lua/colors/solarized.lua`** is consumed by the three `Solarized*`
  rows; its public surface (`set_theme`, `toggle`) is not edited by A.
  Any reshaping there is Candidate B's job.
- **`utils.wordcount`** is consumed by the two WordCount rows; its
  public surface is not edited by A.

## Resolved decisions that bind this sub-PRD's scope

- **Registrar exists (PRD goal #1):** `commands.register(spec)` is the
  public seam. The function `vim.api.nvim_create_user_command` is
  called from one place — inside the registrar — not 18 places across
  `commands.lua`.
- **No access-surface change (PRD constraint #4, non-goal #5):** the
  18 user commands keep their names, argument shapes, and observable
  behavior. The three `Solarized*`, the 13 `ObsCLI*`, and the two
  WordCount commands are all preserved.
- **No leaf-module edits (cycle PRD non-goals #1, #3):** A registers
  against the existing public surfaces of `utils.obsidian_cli`,
  `colors.solarized`, and `utils.wordcount`. Reshaping any of those
  modules is out of scope for this parent.
- **No UI integration tests for the registrar (cycle PRD non-goal #6):**
  the registrar is a pure transformation from spec to a registered
  command — testable by faking `vim.api.nvim_create_user_command` and
  asserting the recorded call shape. `mini.test.new_child_neovim` is
  not used to close this parent.
- **Candidate F folded (PRD goal #6):** the domain split of
  `commands.lua` is a closing sub-issue under A, gated on whether
  the file remains scannable as a single declarative list once the
  registrar lands. Default is "skip the split."

## Resolve-through-implementation items carried forward

- **Registrar location (PRD open question #2):** decide during A's
  first sub-issue whether the registrar lives co-located in
  `lua/config/commands_registrar.lua`, as a local table inside
  `commands.lua`, or promoted to `lua/utils/`. Promote only if a
  second consumer surfaces during A's implementation. Record the
  decision in `issue.md`.
- **Spec-row schema:** the exact shape of a registrar spec row — what
  keys it carries (`name`, `desc`, `nargs`, `complete`, `module`,
  `fn`, error-handling hooks) — is decided in A's first sub-issue
  once the tracer slice is in place. The PRD constrains the outcome
  (one row per command, no per-command boilerplate); the keys
  themselves are an implementation choice.
- **Domain split (Candidate F, PRD goal #6):** decide at A's closing
  sub-issue whether to split `commands.lua` by domain. Default skip;
  promote only if the registered list is no longer scannable.

## Out of scope (carried from cycle PRD)

- Refactoring any module under `lua/utils/obsidian_cli/`. Cycle 02
  closed that surface; A consumes it through its existing public
  `M.*` table.
- Reshaping `utils.wordcount.buf_line_range_wordcount` — tracked in
  `context/refactor-backlog.md`.
- Adding new user commands, renaming existing ones, or changing
  argument shapes. Only the 18 currently-defined commands are in
  scope, and only their registration mechanism is reshaped.
- Reshaping `colors.solarized` — Candidate B's parent issue.
- Reshaping `lua/config/autocmds.lua` (codesign extraction) —
  Candidate D's parent issue.
- Decomposing `lua/colors/solarized.lua` highlights — Candidate C's
  parent issue.
- Generalizing the registrar into a configuration-wide command DSL.
  A's registrar serves `commands.lua`. If another file needs the same
  shape in a future cycle, that is that cycle's decision.
- UI integration tests against a live Neovim editing session for the
  registrar. The seam is testable as a pure transformation from spec
  to recorded `nvim_create_user_command` call.

## Domain validation pass

No new domain terms introduced by this sub-PRD beyond those already
covered by the cycle PRD's domain-validation pass. The terms used here
— **registrar**, **spec row**, **declarative dispatch** — are
pattern-language for module architecture, not domain vocabulary, and
are excluded from `ubiquitous-language.md` per its policy on general
programming concepts. The Neovim-domain terms used (**user command**,
**autocmd**, **statusline**) carry their `product.md` / Neovim-docs
meanings unchanged.
