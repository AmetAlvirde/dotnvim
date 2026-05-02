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

- [ ] `mini.nvim` (or `mini.test` only — decided during Stage 2) is added as
      a `lazy.nvim` plugin spec at `lua/plugins/mini-test.lua`. Neovim
      startup remains clean: `nvim --headless +qa` exits 0.
- [ ] `tests/` directory exists at the repo root.
- [ ] `tests/minimal_init.lua` exists and is the headless bootstrap — it
      prepends the repo root to `runtimepath`, requires `mini.test`, and
      does nothing else. It does NOT load `init.lua` or any plugin from the
      lazy plugin set; the test environment is deliberately minimal.
- [ ] `scripts/test.sh` is executable (`chmod +x`) and runs every
      `*_spec.lua` file under `tests/` via `mini.test`'s collection
      mechanism, exiting with `nvim`'s exit code.
- [ ] `Makefile` exists at the repo root with a single `test` target that
      execs `scripts/test.sh`. `make test` is equivalent to running the
      script directly.
- [ ] One tracer-bullet spec at `tests/tracer_spec.lua` asserts a trivial
      truth (`MiniTest.expect.equality(1, 1)` or equivalent) and passes.
- [ ] `make test` exits 0 with the tracer in place.
- [ ] Temporarily breaking the tracer's assertion makes `make test` exit
      non-zero. Reverted before commit. Verified manually during Stage 2.
- [ ] Output on green is no more than ~5 lines. Output on red shows the
      failing assertion clearly.

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
- New: `tests/minimal_init.lua`
- New: `tests/tracer_spec.lua`
- New: `scripts/test.sh`
- New: `Makefile`
- Modified: `lua/config/plugins.lua` — add the `mini-test` require.
- Modified: `lazy-lock.json` — generated when `mini.nvim` is installed.

The README pointer is **not** added in this sub-issue. It belongs in
sub-issue 2 alongside the real example spec, so that the pointer points at
something a future maintainer would actually want to read.

## Dependencies

None. This is the first sub-issue.
