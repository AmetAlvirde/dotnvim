# Sub-issue — Runner and entry point

## Description

Stand up `mini.test` as a `lazy.nvim` plugin, create the `tests/` directory,
and add a single shell entry point that runs every spec under `nvim
--headless` and exits non-zero on failure. Prove the wiring works end-to-end
with a tracer-bullet spec that asserts `1 == 1`. After this sub-issue
merges, the harness exists and reports green or red; what it tests is
trivial. Sub-issue 2 will replace the tracer with a real spec.

## Dependency classification

| Dependency             | Category                | Testing strategy                                                 |
| ---------------------- | ----------------------- | ---------------------------------------------------------------- |
| `mini.test`            | In-process              | Loaded as a Lua module under Neovim. Test by invocation, not mock. |
| `nvim` binary          | True external (platform) | Invoked by the shell entry point. Not substituted; it *is* the runtime. |
| Shell environment      | True external (platform) | The script must work in `bash`/`zsh` on macOS and Linux.           |
| `lazy.nvim`            | In-process              | Already managing every other plugin in this repo.                |

The runner has no in-Neovim production-vs-test seam in the conventional
sense — `mini.test` is *itself* the seam between specs and the rest of the
config. There is no port to define here.

## Interface design

The "interface" being designed here is the **maintainer-facing entry point
contract**: what a maintainer types and what they see back. There is no Lua
module API being authored in this sub-issue.

**Alternative A — `scripts/test.sh` only.**
A single executable shell script at `scripts/test.sh`. Invocation is
`./scripts/test.sh`. The script changes to the repo root, then execs `nvim
--headless --noplugin -u tests/minimal_init.lua -c "lua MiniTest.run()"
--cmd "set rtp+=." +qa` (exact form decided during implementation). Exits
with `nvim`'s exit code.

**Alternative B — `Makefile` target `make test`, wrapping `scripts/test.sh`.**
Same script as A, plus a `Makefile` with one target. Invocation is `make
test`; muscle memory carries from other repos.

**Alternative C — `Makefile` only, no separate script.**
A `Makefile` containing the full `nvim --headless` invocation inline.
Invocation is `make test`. No `scripts/` directory needed.

**Chosen: B.** `make test` matches the convention most projects use and is
what the encounter statement in the PRD implicitly assumes; a
self-contained shell script is easier to debug, version, and run from
contexts where Make may not be installed (a future CI image, a recovery
shell). Splitting them cleanly separates the entry surface (`make test`)
from the implementation (`scripts/test.sh`). Alternative C was rejected
because Make recipes are an awkward place for multi-line shell logic and
because losing the standalone script removes a debugging affordance for
zero gain.

## Acceptance criteria

- [x] `mini.nvim` (or `mini.test` only — decided during Stage 2) is added as
      a `lazy.nvim` plugin spec at `lua/plugins/mini-test.lua`. Neovim
      startup remains clean: `nvim --headless +qa` exits 0.
- [x] `tests/` directory exists at the repo root.
- [x] ~~`tests/minimal_init.lua`~~ Bootstrap exists — implemented as
      `tests/init.lua`. Prepends repo root to runtimepath and loads
      `mini.test` without touching the main `init.lua` or lazy plugin set.
      Also handles zero-spec short-circuit and explicit `find_files`.
      (See AAR for deviation rationale.)
- [x] ~~`scripts/test.sh`~~ Executable entry point exists — implemented as
      `tests/run` (`chmod +x`). Runs every `*_spec.lua` under `tests/` via
      `mini.test`'s collection, exits with `nvim`'s exit code.
      (See AAR for deviation rationale.)
- [ ] `Makefile` exists at the repo root with a single `test` target.
      **Not done.** Execution brief chose Alternative A (script only).
      (See AAR.)
- [x] ~~`tests/tracer_spec.lua`~~ Real spec delivered immediately as
      `tests/utils/wordcount_spec.lua` (6 cases, `utils.wordcount` public
      API). Tracer skipped — execution brief directed a real spec from the
      start.
- [x] ~~`make test`~~ `./tests/run` exits 0 with specs in place.
- [x] Temporarily breaking an assertion makes `./tests/run` exit non-zero.
      Reverted before commit. Verified manually.
- [x] Output on green is quiet (summary + pass dots). Output on red shows
      the failing assertion, file, and line clearly.

## Proposed tests

This sub-issue's deliverable is the harness itself, so "proposed tests"
here means: what specs prove the harness works.

| Title                    | What it verifies                                                                              |
| ------------------------ | --------------------------------------------------------------------------------------------- |
| tracer: 1 == 1            | The wiring runs end-to-end. Equivalent to Stage 2's First Contact check.                       |
| tracer: deliberate fail   | Run once with a known-failing assertion to confirm `nvim` exits non-zero. Reverted, not committed. |

Only the first is committed. The second is a Stage 2 verification, not a
permanent spec.

## Affected artifacts

- New: `lua/plugins/mini-test.lua`
- New: `tests/init.lua` _(planned as `tests/minimal_init.lua`)_
- New: `tests/utils/wordcount_spec.lua` _(planned as `tests/tracer_spec.lua`)_
- New: `tests/run` _(planned as `scripts/test.sh`)_
- ~~New: `Makefile`~~ — not created; Alternative A chosen during execution.
- Modified: `lua/config/plugins.lua` — add the `mini-test` require.
- Modified: `lazy-lock.json` — generated when `mini.nvim` is installed.
- Modified: `README.md` — one-line Testing section added.
  _(planned for sub-issue 2; moved earlier by the execution brief)_

## Dependencies

None. This is the first sub-issue.
