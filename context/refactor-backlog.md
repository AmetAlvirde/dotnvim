# Refactor backlog

> Deepening candidates that have been surfaced but not yet pursued. Cycle
> pitches consult this list when choosing a next target; cycle AARs append to
> it. Items are removed only when a cycle has closed against them — at which
> point the entry is moved to the "Resolved" section with the closing cycle
> noted.
>
> Surfacing an item here does not commit a cycle to it. The backlog is
> intentionally append-only and unsorted: prioritization happens in the next
> cycle's Flow B exploration, not here. If an item turns out to be wrong or
> obsolete, strike it through with a one-line note explaining why rather than
> deleting it, so the reasoning trail stays intact.

## Entry shape

Each entry has:

- **Title** — short noun phrase identifying the candidate.
- **Surfaced** — cycle / parent issue / AAR where the friction was first noted.
- **Friction** — one or two sentences naming the concrete pain.
- **Why deferred** — why the surfacing cycle did not absorb it.
- **Closed by** — empty until a cycle closes against it, then the cycle's name.

---

## Open

### `utils.wordcount.buf_line_range_wordcount` cannot be unit-tested through its public interface

- **Surfaced:** cycle `01-test-harness`, parent issue `01-harness-foundation`,
  AAR carry-forward and Flags section.
- **Friction:** `buf_line_range_wordcount` calls `nvim_buf_get_lines`, which
  requires a real buffer object. The function cannot be exercised through its
  public interface without spinning up a live Neovim editing session — exactly
  the integration-test surface cycle 01 ruled out. Every other public function
  on `utils.wordcount` has a real spec; this one is the lone hole.
- **Why deferred:** cycle 01's PRD non-goal #1 forbade migrating any existing
  module during the harness cycle. The reshape needed to make this function
  testable is module-shape work, not harness work.
- **Closed by:** _open_

### `lua/config/commands.lua` `pcall(require, ...)` boilerplate

- **Surfaced:** cycle `02-obsidian-cli` pitch planning (this round).
- **Friction:** every user-command wrapper in `lua/config/commands.lua`
  open-codes the same five-line shape — `pcall(require, "utils.obsidian_cli")`,
  bail with `vim.notify` on failure, call one `M.*` function, notify on
  result. Across ~14 wrappers, the load-and-notify scaffolding outweighs the
  one line of behavior in each command. Adding a new command means copying
  the boilerplate.
- **Why deferred:** cycle 02's distinction is structural deepening of
  `obsidian_cli.lua` itself. Folding the commands.lua refactor into the same
  cycle would split focus across two unrelated friction surfaces and obscure
  the deepening's scope.
- **Closed by:** _open_

---

## Resolved

_(Empty. Entries move here with the closing cycle's name when a cycle closes
against them.)_
