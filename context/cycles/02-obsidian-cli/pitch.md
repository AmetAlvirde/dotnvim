# Pitch — Deepen `utils.obsidian_cli`

Problem: `lua/utils/obsidian_cli.lua` is 815 lines exposing 14 leaf functions,
each of which open-codes the same four-step pipeline — resolve the current
buffer to a vault-relative path, build an `obsidian` CLI command line, invoke
`vim.fn.systemlist` against it, then parse the result and present it via
quickfix or a scratch buffer. The pipeline is never named or factored, so the
parsing and presentation steps cannot be exercised without a live Obsidian
process and a live editing session.

Who: The maintainer (author), on the next change to this module — adding a new
CLI subcommand wrapper, fixing a parser regression on a malformed CLI line, or
correcting how a result lands in quickfix. With the harness now standing
(cycle 01), this is the first change to `obsidian_cli.lua` that would be
expected to ship with tests, and the current shape forbids that.

Gap: `mini.test` is in place and proven (cycle 01 closed all green, including
a real spec over `utils.wordcount`). Running it against `obsidian_cli.lua` as
it stands would either require a live Obsidian process and a live editing
session — explicitly out of scope per cycle 01's PRD non-goals — or specs that
monkey-patch `vim.fn.systemlist`, `vim.fn.setqflist`, and `vim.api.nvim_*`,
exactly what cycle 01's acceptance criterion forbade ("no reaching into local
functions or monkey-patching internals"). The harness exists; the module's
shape blocks its use.

Distinction: This cycle treats `obsidian_cli.lua` as one unit of structural
deepening rather than a sequence of leaf-by-leaf cleanups. The pipeline is
named (**command builder → shell adapter → output parser → presenter**) and
each step becomes a layer with a public, unit-testable interface. The shell
adapter is the only layer that touches `vim.fn.systemlist` and is isolated
behind an injectable seam, so parsers and presenters can be tested against
captured sample CLI outputs with no `obsidian` invocation. The leaf
operations (`orphans_to_quickfix`, `tasks_to_quickfix`,
`backlinks_counts_to_quickfix`, …) survive as short compositions of those
layers.

Form / access surface: The user commands in `lua/config/commands.lua`
(`:ObsCLITasks`, `:ObsCLIOrphans`, `:ObsCLIBacklinks`, …) are the access
surface for users; they call the `M.*` functions in `obsidian_cli.lua`. The
deepening must preserve those entry points unchanged — same names, same
arguments, same happy-path behavior. The new surface introduced by the
deepening — the command builder, the shell adapter, the parsers — is the
access surface for *tests*. Success means the parsing logic for every CLI
subcommand has at least one unit test against a captured sample output, with
no live `obsidian` invocation.
