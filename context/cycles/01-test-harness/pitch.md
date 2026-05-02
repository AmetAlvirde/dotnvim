# Pitch — Test harness

Problem: This Neovim configuration has no test harness, so every refactor closes
on a manual smoke check rather than a verifiable signal, which makes the
process spec's TDD workflow impossible to honor on subsequent cycles.

Who: The maintainer (author) attempting to deepen any of the shallow modules
surfaced during Flow B exploration — `lua/utils/obsidian_cli.lua` (815 lines,
flat list of leaf operations sharing a hidden pipeline), the theme-refresh
wiring spread across `lua/plugins/lualine.lua`, `lua/colors/solarized.lua`, and
`lua/config/autocmds.lua`, the 547-line highlight wall in
`lua/colors/solarized.lua`, and the command boilerplate in
`lua/config/commands.lua`.

Gap: Available Neovim test frameworks exist (`mini.test`,
`plenary.test_harness`, `busted`), but none are wired into this repo. There is
no `tests/` directory, no headless runner, no CI invocation, and no convention
establishing how a module under `lua/utils/` or `lua/colors/` is meant to be
tested. Adopting a harness opportunistically alongside another refactor would
couple the harness choice to that refactor's needs and bury its own trade-offs
inside an unrelated change.

Distinction: The harness is treated as a first-class refactor cycle with its
own pitch, PRD, and AAR — not scaffolding bolted onto a feature. It commits to
one runner, one location convention, and one entry point for "run all tests
headless." Subsequent refactor cycles inherit a working harness instead of
relitigating the choice. Without this, every other candidate from the
exploration closes against an unverifiable signal.

Form / access surface: A single command — `make test` or equivalent — that
runs every spec headless under Neovim and exits non-zero on failure. Backed by
a `tests/` directory with at least one passing example spec demonstrating how
a `lua/utils/` module is tested through its public interface, and a one-line
README pointer so a future maintainer encountering the repo cold can run it
without reading the harness internals.
