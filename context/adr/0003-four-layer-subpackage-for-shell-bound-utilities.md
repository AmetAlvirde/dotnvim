# Four-layer subpackage layout for shell-bound utility modules

_Made during: 02-obsidian-cli / 13-deepen-obsidian-cli (sub-issues #14–#20)_
_Scope: product_
_Status: accepted_

`utils.obsidian_cli` (and future shell-bound utility modules in this
configuration) are implemented as a submodule directory
(`lua/utils/<name>/`) containing four named sibling layers — **command
builder** (`command.lua`), **shell adapter** (`shell.lua`), **output parser**
(`parsers.lua`), **presenter** (`presenter.lua`) — plus a **composition root**
(`init.lua`) that re-exports the public `M.*` surface. The shell adapter is the
only layer that invokes shell-execution primitives (`vim.fn.systemlist` or
equivalent). It exposes a module-level setter seam (`set_runner` /
`reset_runner`) so tests can substitute a fake without adding parameters to the
production `M.*` signatures. Pure layers (`command`, `parsers`) need no seam
and are independently `require`-able.

## Considered Options

- **(a) Single file with named sections:** visual layer boundaries only; tests
  must still reach into sub-tables of the parent module. Rejected — the
  `require`-boundary enforcement that motivates the deepening is absent.
- **(b) Flat sibling files** (`obsidian_cli_command.lua`, etc.): mechanically
  equivalent but pollutes `lua/utils/` with prefixed names. Rejected.
- **(c) Submodule directory (accepted):** Lua resolves
  `require("utils.obsidian_cli")` to `init.lua` automatically;
  `lua/config/commands.lua` is unchanged; each sibling is independently
  requireable.

## Consequences

- Pure-layer tests (`parsers`, `command`) `require` the sibling module directly
  with no seam; only composition-path tests need the shell-adapter setter.
- Modules whose helpers beyond `vim.fn.systemlist` are impure may need
  additional setter-based seams following the same pattern. The first qualified
  extension is `parsers.set_resolver` / `parsers.reset_resolver` (#20), which
  wraps `vault_relpath_to_abs` (`vim.loop.fs_stat`). The pattern accommodated
  this without structural revision.
- `presenter.lua` testability was not resolved in this cycle. The layer exists
  but has no unit tests. A future cycle decides between pure-transformation
  factoring and child-Neovim assertions.
