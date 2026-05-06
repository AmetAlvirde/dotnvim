# PRD — Cycle 03, Configuration Deepening

## Focus

Apply the shape-deepening discipline established by cycles 01 and 02 to the
configuration's wiring layer — `lua/config/commands.lua`,
`lua/config/autocmds.lua`, `lua/colors/solarized.lua`, and
`lua/plugins/lualine.lua`. Each of the four files carries application logic
in-place that should live behind a public, testable seam. The cycle extracts
those seams, one parent issue per file, and leaves each wiring file declarative.

## Intentions

1. Establish that wiring files in this configuration earn their place by being
   declarative — registrations, subscriptions, autocmd bindings — and not by
   carrying application logic that could live behind a named seam.
2. Make the test-writing pattern from cycle 02 (pure modules tested directly;
   setter seams for shell or editor calls; `mini.test` child Neovim only when
   editor state genuinely matters) the default shape for module-shape work in
   this configuration, regardless of whether the module is in `utils/`,
   `config/`, `colors/`, or `plugins/`.
3. Lower the cost of the next change to each of the four surfaces — adding an
   ObsCLI command, adding a theme-change consumer, tweaking a highlight section,
   disabling the macOS re-signing workaround — from "edit a wiring file
   in-place" to "compose against the seam the cycle introduced."

## Goals

1. **Candidate A — `commands.lua` declarative dispatch (parent issue).** A
   `commands.register(spec)` registrar exists with a public, unit-testable
   interface. `commands.lua` becomes a list of spec rows; the per-command
   `pcall(require, ...)` → call → notify shape is gone. The 19 user commands
   currently defined retain their names, argument shapes, and observable
   behavior.
2. **Candidate B — theme-change subscribe seam (parent issue).**
   `colors.solarized` exposes `subscribe(fn)` and emits a single event on
   `set_theme`/`toggle`/`setup`. Lualine subscribes once. The
   `vim.loop.new_timer()` polling timer is deleted. Stray `print()` debug
   statements in the theme-change path are removed. The four other reaction
   mechanisms (two autocmds, the explicit `:LualineRefresh` calls, `FocusGained`
   re-running setup) collapse to one signal — or are explicitly retained with a
   recorded reason.
3. **Candidate C — `solarized.lua` highlight decomposition (parent issue).**
   Highlights are split into named section modules (base, syntax, treesitter,
   markdown, obsidian, template literals, …). Each section exposes
   `highlights(c) → table`; `setup()` composes them. Each section is exercisable
   as a pure unit test.
4. **Candidate D — macOS `codesign` workaround extraction (parent issue).**
   `lua/utils/macos_codesign.lua` exists, exposing `resign_lazy_plugins()`. The
   autocmd in `lua/config/autocmds.lua` becomes one line. The utility follows
   ADR-0003's four-layer shape (`command.lua` builds the `find` invocation,
   `shell.lua` carries the runner seam) — no presenter or parser layers needed.
5. **Candidate E (folded into B unless it grows).** `get_os_theme` in
   `solarized.lua` is extracted to `lua/colors/os_theme.lua` with a `set_runner`
   setter and a cached last value, so the `defaults read AppleInterfaceStyle`
   shell-out no longer fires on every `FocusGained`. Either lands as part of B's
   surface or as a small follow-up sub-issue under B; it does not become its own
   parent issue.
6. **Candidate F (may not need its own parent).** Splitting `commands.lua` by
   domain (`solarized`, `obsidian_cli`, `wordcount`) is folded into A's closing
   surface refinement if the registrar makes the file size moot, the split is
   trivial once rows exist, or the file remains scannable as a single list.
   Promoted to its own parent only if A's closure surfaces a real reason to
   split.
7. The full test suite — including all cycle 01 and cycle 02 specs — exits 0 on
   `./tests/run` after each parent issue closes.
8. ADR-0003 (four-layer subpackage for shell-bound utilities) continues to apply
   to the new shell-bound utilities introduced by D and E. If a new pattern
   emerges from B (subscribe registry) that proves durable across consumers, an
   ADR-0004 candidate is recorded — decision deferred until B closes.

## Non-goals

1. Refactoring any module under `lua/utils/obsidian_cli/`. Cycle 02 closed that
   surface; revisiting it in this cycle splits focus.
2. Reshaping `utils.wordcount.buf_line_range_wordcount`. Tracked in
   `context/refactor-backlog.md`; deferred to a later cycle.
3. Adding new user commands, new theme variants, or new highlight groups. Only
   existing surfaces are reshaped.
4. Adding new plugins. The cycle is internal-shape work.
5. Changing user-facing keymaps, command names, or command argument shapes. The
   access surface stays observably identical.
6. Integration tests that drive a full live Neovim editing session.
   `mini.test.new_child_neovim` is allowed where editor-state isolation is
   genuinely needed (consistent with cycle 02's precedent), but no parent issue
   closes by writing a UI integration test where the seam itself was testable as
   a pure transformation.
7. CI integration. Local-only entry point, same as cycles 01–02.
8. Refactoring `lua/config/autocmds.lua` beyond the codesign extraction in D.
   The file's other autocmd handlers are out of scope; if friction surfaces
   during D's implementation, it is recorded in `refactor-backlog.md`.
9. Generalizing the registrar from A into a global "command DSL" for the
   configuration. A's registrar serves `commands.lua`; if another file needs the
   same shape, that is a future cycle's call.

## User stories

1. As a maintainer adding a new ObsCLI command, I want to register it as one row
   in a spec table, so that the cost of adding a command is one line of intent
   and not 14 lines of boilerplate.
2. As a maintainer auditing how the statusline reacts to a theme flip, I want
   exactly one named place that emits the event and one named place that
   subscribes, so that I can reason about the wiring without scanning five
   mechanisms across three files.
3. As a maintainer tweaking the markdown highlight section, I want to edit one
   section module and have its tests exercise only that section, so that the
   change is local and the diff is reviewable.
4. As a maintainer auditing what in this configuration shells out to macOS, I
   want the `codesign` workaround in one named utility with a runner seam, so
   that I can disable, document, or test it without touching `autocmds.lua`.
5. As a maintainer running the test suite headlessly, I want each extracted seam
   (registrar, subscribe registry, highlight sections, codesign command builder,
   `os_theme` runner) to be exercised by at least one unit test against
   `./tests/run`, so that a regression in any of these surfaces cannot reach the
   configuration silently.
6. As a maintainer of the four wiring files at cycle close, I want each one to
   read top-to-bottom as a declarative spine — registrations, subscriptions,
   autocmd bindings — so that the file's purpose is visible without reading the
   modules it wires together.

## Encounter statements

None. Same maintainer-internal cycle shape as cycle 02 — the encounter is the
test-writing experience and the read-the-wiring- file experience, both already
covered by the user stories above.

## Constraints and assumptions

1. Runtime is Neovim 0.11.0+ (per `product.md`).
2. `mini.test` from cycle 01 is the test runner. No new test tooling is
   introduced.
3. ADR-0001 (`mini.test`), ADR-0002 (issue numbering), and ADR-0003 (four-layer
   subpackage) all apply. ADR-0003 governs Candidates D and E.
4. The 19 user commands currently defined in `commands.lua` keep their names and
   argument shapes. The three `:Solarized*` commands keep theirs. The two
   `WordCount` commands keep theirs.
5. Theme-change observable behavior — the statusline reflecting the active
   palette after `:SolarizedToggle`, after a system theme flip on macOS, and
   after `FocusGained` — is preserved. The internal mechanism collapses; the
   externally observable behavior does not.
6. Highlight output (the actual `:hi` groups defined after
   `colors.solarized.setup()`) is preserved across Candidate C. A spec that
   asserts a stable subset of the resulting highlight table is the closure
   signal.
7. The macOS re-signing workaround keeps firing on the same trigger it fires on
   today (Lazy install/update events) with the same observable effect on the
   user's `nvim` startup after a plugin update on macOS.
8. Tests run without network access, without a live `obsidian` process, without
   a live editor session unless `mini.test.new_child_neovim` is genuinely
   required.
9. Each parent issue closes independently behind its own PR. Sub-issue numbering
   follows ADR-0002 — sequential GitHub issue numbers, not cycle-local.
10. The four parent issues are independently scoped — closing any one does not
    block the others — but the recommended cycle sequencing (resolved below in
    open question #1) is A → D → B → C so test patterns and the easiest
    extraction land before the largest reshape.

## Success metrics

These are architectural compliance checks — binary, verifiable.

1. After Candidate A closes, `lua/config/commands.lua` contains no
   `pcall(require, "utils.obsidian_cli")` block. Each of the 19
   currently-defined user commands is registered through the registrar.
2. After Candidate A closes, every user command in `commands.lua` is registered
   through `commands.register`; zero direct `vim.api.nvim_create_user_command`
   calls and zero direct `pcall(require, "utils.…")` calls remain in
   `commands.lua`. (Line-count threshold removed in sub-issue #28: line counts
   do not shape the contract. Structural outcome verified by grep.)
3. After Candidate B closes,
   `grep -n 'vim\.loop\.new_timer' lua/plugins/lualine.lua` returns zero
   matches.
4. After Candidate B closes,
   `grep -rn '^\s*print(' lua/colors/ lua/plugins/lualine.lua` returns zero
   matches in the theme-change code paths.
5. After Candidate B closes, `colors.solarized` exposes a `subscribe(fn)`
   function with at least one passing unit test under `tests/colors/`.
6. After Candidate C closes, `lua/colors/solarized.lua` no longer contains a
   single highlight table over 100 entries. Highlights are composed from section
   modules, each exposing `highlights(c) → table`, each with at least one unit
   test.
7. After Candidate D closes, `lua/utils/macos_codesign.lua` exists, exposes
   `resign_lazy_plugins()`, and follows the ADR-0003 four-layer pattern
   (`command.lua`, `shell.lua` minimum). The `BufWritePost` / Lazy autocmd in
   `autocmds.lua` becomes one line.
8. After each parent issue closes, `./tests/run` exits 0 on the whole suite.
9. After each parent issue closes, `PATH=/usr/bin:/bin ./tests/run` exits 0 (or
   equivalent — the suite passes with `obsidian` and `codesign` absent from
   `$PATH`).
10. No reaching into local functions or monkey-patching internals in any new
    spec. Carry-forward acceptance criterion from cycles 01 and 02, still
    binding.

## Success signals

1. The next change to any of the four wiring files is a one-row edit (A), a
   one-line subscriber addition (B), a one-section edit (C), or a one-line
   workaround toggle (D) — not a search through hundreds of lines.
2. A future cycle that needs the same registrar shape elsewhere in the
   configuration can either reuse A's `commands.register` or extract it to
   `lua/utils/` without a redesign.
3. A future cycle that needs another `colors.solarized` consumer subscribes to
   one signal rather than rediscovering the five-mechanism layering.
4. The macOS re-signing workaround can be disabled by commenting out one autocmd
   line and the rest of the configuration is unaffected.

## Open questions

### 1. Parent issue sequencing — RESOLVED → A → D → B → C

The cycle exploration's recommendation, carried in.

Reasoning:

- **A first.** Lowest risk, lowest entanglement. No theme state, no live-editor
  behavior, no shell-out. Pure data-driven refactor against the already-stable
  `utils.obsidian_cli` `M.*` surface from cycle 02. Establishes the test pattern
  (faking `vim.api.nvim_create_user_command`) that B and D will reuse.
- **D second.** Small, ADR-0003 pattern reuse, builds confidence with the
  four-layer shape on a new module before B's larger reshape.
- **B third.** Highest leverage gain — deletes the polling timer, consolidates
  four-or-five reaction mechanisms into one signal — but also the most
  observable risk surface. Wants A's and D's test patterns proven before opening
  it up.
- **C fourth.** Purely structural; easier after B because theme-change handlers
  have consolidated, so the highlight-section modules don't have to coexist with
  five-channel reaction wiring during the reshape.
- **E folded into B.** The `FocusGained` shell-out fires only because `setup()`
  re-runs on focus, which is one of the five reaction mechanisms B is
  consolidating. The seam is most natural to extract while B's seam is being
  designed.
- **F folded into A's closure (or skipped).** A registrar-driven `commands.lua`
  may not need a domain split; if it does, A's closing sub-issue handles it.

Trade-offs preserved here for the AAR's record:

- **(a) A → B → C → D**: candidate-letter order. Rejected — runs B before D's
  smaller pattern reuse can validate the test approach on a new module type.
- **(b) D → A → B → C**: smallest first. Rejected — A also establishes the
  registrar test pattern that D's eventual presenter / autocmd-binding tests
  will reuse.
- **(c) B → A → C → D**: highest-leverage first. Rejected — opens the
  highest-risk surface before the test patterns it will rely on are established.
- **(d) A → D → B → C**: chosen. Trades a one-cycle wait on B's leverage gain
  for two prior parent issues' worth of test-pattern validation.

### 2. Should A's `commands.register` live in `lua/utils/` or in `lua/config/`? — `RESOLVE THROUGH IMPLEMENTATION`

If only `commands.lua` consumes the registrar within this cycle, keeping it
co-located in `lua/config/commands_registrar.lua` (or as a local table in
`commands.lua` itself) avoids premature promotion to a "utility." If A surfaces
a second consumer during implementation, promotion to `lua/utils/` is warranted.
Decide in A's first sub-issue, record in A's `issue.md`.

### 3. Should B's subscribe registry generalize to a configuration-wide event bus? — `RESOLVE THROUGH IMPLEMENTATION`

Tempting but speculative. The only known consumer today is lualine. If a second
consumer surfaces during B's implementation (treesitter overrides, another
statusline plugin, the sign column), generalize then. Otherwise scope strictly
to `colors.solarized.subscribe`.

### 4. ADR-0004 candidate for the subscribe-registry pattern? — `RESOLVE THROUGH IMPLEMENTATION`

If B lands cleanly and a second consumer arrives in this cycle or the next, an
ADR scoping the subscribe-registry shape (registry table, single emit point,
idempotent unsubscribe) is warranted. Defer until B closes — premature ADRs
codify guesses, per the ADR-0003 precedent from cycle 02.

### 5. Highlight-section testing depth in C — `RESOLVE THROUGH IMPLEMENTATION`

Each section's `highlights(c) → table` is unit-testable as a pure function
(assert expected groups present given an input palette). Whether to also assert
the _composed_ output of `setup()` matches a stable snapshot, or to stop at
per-section tests, is a sub-issue call during C. The risk is that per-section
tests pass while the composition order regresses; a snapshot test catches that
but is churnier to maintain.

### 6. Candidate F as its own parent? — RESOLVED → no, fold or skip

Promoted to its own parent only if A's closing sub-issue surfaces a real reason
to split. Default is "the registrar makes the file size moot; one declarative
list reads fine."

## Domain validation pass

Walking the PRD for terms a domain expert (a user of this Neovim configuration)
would use:

- **statusline**, **theme**, **highlight group**, **autocmd**, **user command**,
  **keymap** — Neovim-domain vocabulary used throughout. Already implicitly in
  scope per `product.md`'s "access surface" framing; not domain-specific to this
  configuration in a way that would warrant glossary entries beyond what the
  Neovim docs already define.
- **registrar**, **subscribe registry**, **section module**, **runner seam** —
  pattern-language for module architecture, not domain terms. Excluded from
  `ubiquitous-language.md` per its policy on general programming concepts. If
  the subscribe-registry pattern proves durable across cycles, an ADR captures
  it.
- **vault**, **vault root**, **vault-relative path**, **Obsidian CLI** — already
  in `ubiquitous-language.md` from cycle 02. Used in this PRD only when
  referencing the access surface that Candidate A's registrar will register; no
  new entries needed.
- **macOS re-signing**, **`codesign` workaround**, **Lazy install events** —
  platform / package-manager vocabulary. Used in Candidate D's framing. Not
  domain terms in the product-language sense; excluded from the glossary.

Exit condition: every domain term in the PRD is defined in
`ubiquitous-language.md`. No new terms introduced by this cycle — the deepening
is architectural, not domain-extending.

Per the skill's required handoff: load `sdp-domain-validate` before PRD exit if
any of the above re-classifications is contested.
