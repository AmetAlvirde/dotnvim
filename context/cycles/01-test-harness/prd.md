# PRD — Test harness

## Focus

Stand up a headless test harness that future refactor cycles can verify
against, with one runner choice committed, one spec-location convention
committed, and one entry point that runs every spec.

## Intentions

1. Make TDD honest in this repo — every cycle from this one forward closes
   against a verifiable signal, not a manual smoke check.
2. Commit to one runner. Do not leave the choice ambient for later cycles to
   relitigate.
3. Lower the activation cost for writing a test — a maintainer should add a
   spec by copying one file and editing it, with no harness preamble.

## Goals

1. A single command runs every spec headless and exits non-zero on failure.
2. At least one passing example spec exists, exercising a real
   `lua/utils/` module through its public interface.
3. A maintainer encountering the repo cold can run the test suite without
   reading the harness internals — discoverable from a README pointer.
4. The runner choice is recorded as an ADR (hard to reverse, surprising without
   context, real trade-off).
5. The spec-location convention is documented in one place that future cycles
   can point at.

## Non-goals

1. Migrating any existing module to TDD in this cycle. The harness lands; the
   migrations are subsequent cycles.
2. Tests for plugin-spec files in `lua/plugins/`. Those are mostly declarative
   `lazy.nvim` tables — tests there add ceremony without leverage.
3. Integration tests that drive a full Neovim editing session. Unit tests at
   module interfaces are the focus; UI-level tests are explicitly out.
4. CI integration. A local entry point is enough; whether it runs in GitHub
   Actions is a later decision.
5. Backfilling tests for the existing 815-line `lua/utils/obsidian_cli.lua`.
   Tests for that module are written *during* its refactor cycle, against the
   deepened interface — not against today's shallow surface.

## User stories

1. As a maintainer about to refactor `lua/utils/obsidian_cli.lua`, I want a
   working harness so I can write a tracer-bullet spec before changing any
   code, as Stage 2 of the process requires.
2. As a maintainer adding a new module under `lua/utils/`, I want one clear
   convention for where its spec lives and how it is invoked, so I do not
   re-derive the layout each time.
3. As a maintainer returning to this repo after time away, I want one command
   that runs the suite and reports green or red, without my having to read
   harness source to remember how it works.

## Encounter statements

1. When the maintainer runs the suite entry point on a clean tree, they should
   see output proportional to the outcome — quiet on green, loud only on red.
   A wall of framework chatter on every successful run is the failure mode.

## Constraints and assumptions

1. Runtime is Neovim 0.11.0+ (per `product.md`).
2. macOS is the primary target; Linux secondary. A runner that is awkward on
   macOS is rejected.
3. No new dependency outside the `lazy.nvim`-managed plugin set unless the
   trade-off is recorded in the runner ADR.
4. Tests must run without network access.
5. Lua version is whatever Neovim 0.11 ships (LuaJIT). A runner that requires
   a separate system Lua is acceptable only if it can also run under `nvim
   --headless` on this LuaJIT.
6. The spec location convention chosen here will outlive the cycle — picking
   one and committing matters more than picking the theoretically best one.

## Success metrics

These are architectural compliance checks — binary, verifiable.

1. Running the chosen entry point on a tree with zero specs exits 0.
2. Running it with one passing example spec exits 0.
3. Running it with one deliberately failing spec exits non-zero.
4. The example spec imports a real `lua/utils/*` module and asserts behavior
   through its public interface — no reaching into internal locals or
   monkey-patching private functions.
5. The README (or equivalent surface named in `product.md`) contains a
   pointer to the entry point in one sentence.
6. The runner ADR exists in `context/adr/`, registered in
   `context/adr/INDEX.md`, with `Scope: product`.

## Success signals

1. The next refactor cycle's pitch can write "the test suite" without
   qualifying what that means.
2. Adding a new spec is a copy-edit of an existing one — no boilerplate setup
   reproduced from memory or from the harness docs.

## Open questions

### 1. Runner choice — RESOLVED → `mini.test`

See ADR-0001. Trade-off analysis preserved below for the AAR's record.

`mini.test`, `plenary.test_harness`, or `busted`.

**`mini.test`** (`echasnovski/mini.nvim`)

- \+ Headless-first; designed to run under `nvim --headless` with minimal
  output on green.
- \+ No external Lua or luarocks toolchain. Runs entirely under Neovim's
  bundled LuaJIT.
- \+ Small footprint — `mini.test` can be pulled as a single submodule of
  `mini.nvim` without taking the rest.
- \+ Supports child Neovim processes for test isolation, which matters for
  any module that mutates editor global state.
- − Smaller community than busted; idioms are mini-specific rather than the
  RSpec/busted convention most Lua devs know.
- − Async ergonomics are light; tests that touch `vim.defer_fn` or timers
  need explicit waits.

**`plenary.test_harness`** (`nvim-lua/plenary.nvim`)

- \+ Already a transitive dependency in this repo —
  `lua/plugins/obsidian.lua:8` declares `nvim-lua/plenary.nvim` as a
  dependency. Adopting it adds zero new plugins.
- \+ Busted-flavored API (`describe`/`it`); familiar to anyone who has
  written Lua tests before.
- \+ Headless via `:PlenaryBustedDirectory`, which is the documented path.
- − Plenary's test module is a known weak spot — sparse docs, surprising
  failure modes around async, periodic API drift between releases.
- − Coupling the test suite to plenary means a plenary upstream break also
  breaks the test suite. The plugin's primary purpose is utilities for
  other plugins, not testing infrastructure.

**`busted`** (`lunarmodules/busted`)

- \+ The Lua testing standard. Richest API, best docs, most stable.
- \+ Strong community; predictable behavior across Lua versions.
- − Requires luarocks plus a separate Lua runtime — adds a non-Neovim
  toolchain dependency to a Neovim-only repo.
- − Running busted against the `vim.*` API requires either running it under
  `nvim --headless` (which forfeits much of busted's strengths) or stubbing
  `vim.*` (which forfeits the realism that the in-Neovim runners give for
  free).
- − The surfaces this config exercises — autocmds, highlight groups, user
  commands, `vim.fn.systemlist` — are awkward to fake outside Neovim.

**Shape of the trade-off.** `mini.test` and `plenary` both run inside Neovim,
so `vim.*` is the real API. `busted` runs outside, so it forces fakes —
ergonomic for pure-logic modules, painful for anything that touches the
editor. Between the in-Neovim options, plenary is already on disk but is
not primarily a testing tool; `mini.test` is purpose-built but adds one
plugin entry. The decision shape is: tooling already in the dependency tree
versus tooling whose primary job is what we are asking it to do.

### 2. Spec location convention — RESOLVED → `tests/` at repo root, mirroring `lua/`

Specs live at `tests/<path>/<module>_spec.lua`. Example:
`lua/utils/wordcount.lua` → `tests/utils/wordcount_spec.lua`. Co-location was
rejected because any file under `lua/` is `require`-able by the runtime; stray
spec files becoming accidentally importable is a real footgun. The `_spec/`
subfolder pattern is fine but uncommon enough that future-you would not
remember it. No ADR — the choice is not surprising to a future reader.

Original options preserved below for the AAR's record.

Three plausible layouts:

- **`tests/` at repo root**, mirroring `lua/`. Specs are
  `tests/utils/obsidian_cli_spec.lua`. Pro: clear separation of
  production and test code. Con: a second tree to keep mentally synced
  with `lua/`.
- **Co-located `*_spec.lua` next to the module**, e.g.
  `lua/utils/obsidian_cli.lua` next to `lua/utils/obsidian_cli_spec.lua`.
  Pro: locality — the test is right there. Con: pollutes the runtime tree
  with files that should never be loaded by `require`.
- **`lua/<module>/_spec/`** subfolder. Pro: locality without polluting
  flat namespaces. Con: an extra folder per module.

Decide before writing the example spec; the choice propagates to every
future spec and renaming later means mass renames.

### 3. Faking `vim.*` for editor-touching modules — `RESOLVE THROUGH IMPLEMENTATION`

`lua/utils/obsidian_cli.lua` calls `vim.fn.systemlist`, `vim.api.nvim_*`,
`vim.fn.setqflist`. Whether the right answer is dependency-injection
(pass a `runner` table into the module), the harness's built-in mocking, or
something else depends on which runner wins question 1 and how the module
is shaped after candidate #2's refactor. Do not pre-decide.

### 4. CI integration — `RESOLVE THROUGH IMPLEMENTATION`

Already a non-goal for this cycle. Listed here so the next cycle's pitch
can decide based on whether local-only proves insufficient in practice.

## Domain validation pass

The vocabulary in this PRD is general programming/tooling — *spec*,
*runner*, *harness*, *headless*, *fake*. None are terms a domain expert (a
user of this Neovim config) would use to describe the product. Per the
glossary rule that excludes general programming concepts, no entries are
added to `context/ubiquitous-language.md` from this PRD. The exit condition
for the validation pass is met by the exclusion: there are no qualifier
smells, no ambiguous domain terms, and no glossary discrepancies because
the relevant glossary surface is empty by design.
