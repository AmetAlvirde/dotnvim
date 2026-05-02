# Sub-issue — Layer skeleton + tracer

GitHub issue: #14. First sub-issue of parent #13. The Stage-1 tracer
slice for the cycle: stand up the four-layer submodule directory
without changing any external behavior, prove via a smoke spec that
the move is honest, and leave the codebase in a green state from which
incremental parser-by-parser sub-issues (#15+) can land.

## Description

Move `lua/utils/obsidian_cli.lua` (815 lines, 14 leaf functions) into
the submodule directory `lua/utils/obsidian_cli/` split across
`init.lua`, `command.lua`, `shell.lua`, `parsers.lua`,
`presenter.lua`. Wire the shell-adapter seam in `shell.lua` —
`set_runner(fn)` / `reset_runner()` plus a default that wraps
`vim.fn.systemlist`. Preserve the 14 `M.*` exports byte-for-byte at
the call site: `lua/config/commands.lua` is not edited and must
continue to load. After this sub-issue merges, the module loads
through the new directory layout, all 14 leaf functions still work
end-to-end against a real `obsidian` binary, and a smoke spec proves
the layout is wired. **No new parser tests yet** — that is what
sub-issues #15+ deliver against the layered shape.

## Dependency classification

| Dependency                                            | Category                  | Testing strategy                                                                                                                          |
| ----------------------------------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `obsidian` CLI binary                                 | True external (platform)  | Not invoked in this sub-issue. The tracer spec must pass with `obsidian` absent from `$PATH`.                                             |
| `vim.fn.systemlist`                                   | In-process (Neovim API)   | Wrapped by `shell.lua`'s default runner. The seam exists from this sub-issue forward but is not exercised by the tracer.                  |
| `vim.fn.setqflist`, `vim.api.nvim_create_buf`, etc.   | In-process (Neovim API)   | Live inside `presenter.lua`. Not invoked by the tracer.                                                                                   |
| `lua/config/vaults.lua` (`VAULT_ROOTS`)               | In-process                | Required at module load time, same as today. No test substitution.                                                                        |
| `mini.test`                                           | In-process                | Loaded via cycle 01's harness. Spec runs through `./tests/run`.                                                                           |
| `lua/config/commands.lua`                             | In-process (consumer)     | Must continue to `require("utils.obsidian_cli")` and resolve to `init.lua` automatically. Verified by `git diff` showing no edits.        |

The seam being introduced (`set_runner` on `shell.lua`) has two
justified adapters: the production runner (wraps `vim.fn.systemlist`)
and the test fakes that future sub-issues will inject. Seam discipline
check passes — something external (the shell command result) genuinely
varies across this seam, and at least two adapters exist.

## Interface design

The maintainer-facing surface (the 14 `M.*` functions on
`utils.obsidian_cli`) is unchanged — that is a hard constraint from
the parent issue. The new surface this sub-issue introduces is the
**internal layer surface** between `init.lua` and the four siblings.
Two alternatives, with meaningfully different shapes:

### Alternative A — Layers carry per-subcommand semantics; `init.lua` composes thinly

- `command.lua`: per-subcommand builders. `M.tasks(opts)` →
  `"obsidian tasks todo verbose"`; `M.search_context(query)` →
  `"obsidian search:context query=" .. shellescape(query)`; one
  builder per leaf wrapper. Plus `M.shellescape(s)` re-exported.
- `shell.lua`: `M.run(cmdline)` → `lines, err`. Default runner wraps
  `vim.fn.systemlist`. `M.set_runner(fn)` and `M.reset_runner()`
  expose the seam.
- `parsers.lua`: per-subcommand parsers.
  `M.tasks_verbose(lines)` → items; `M.unresolved_verbose(lines)` →
  items; `M.paths(lines)` → items; `M.backlinks_json(text)` → rows;
  `M.extract_bookmark_note_path(line)` → path. Each parser is the
  unit a future test fixture pairs with.
- `presenter.lua`: presentation primitives plus quickfix navigation
  helpers — `M.to_quickfix(title, items)`, `M.scratch(title, lines)`,
  `M.find_quickfix_win()`, `M.qf_focus_row_for_task_ref(ref)`,
  `M.get_current_qf_item()`.
- `init.lua`: thin compositions.
  `M.tasks_to_quickfix(opts) = command.tasks(opts) → shell.run →
  parsers.tasks_verbose → presenter.to_quickfix`. Vault-path
  helpers (`abs_to_vault_relpath`, `vault_relpath_to_abs`) live as
  module-private locals in `init.lua` — they are not parsers
  (they touch `vim.loop`) and they are not the deepening target.

### Alternative B — Layers as generic primitives; `init.lua` keeps per-leaf glue

- `command.lua`: `M.build(parts)` and `M.shellescape(s)`. No
  per-subcommand builders.
- `shell.lua`: same as A.
- `parsers.lua`: generic primitives only —
  `M.parse_path_line_text(line)`, `M.parse_grouped_lines(lines)`,
  `M.try_decode_json_object(text)`. No per-subcommand parsers.
- `presenter.lua`: same as A.
- `init.lua`: holds the per-subcommand parse-and-glue logic for
  every leaf — calling `parsers.parse_path_line_text` in a loop and
  shaping items inside the leaf.

### Comparison

- **Leverage.** A is higher leverage at the layer boundary —
  `parsers.tasks_verbose(lines)` does the whole subcommand's parse in
  one call; B forces the caller to thread primitives. PRD goal #4
  ("the 14 leaf functions become short compositions of the four
  layers") is what A delivers and B sabotages.
- **Locality.** A concentrates per-subcommand parsing in
  `parsers.lua`; future format-drift fixes change one named function
  in one file. B scatters parse-and-glue logic between `parsers.lua`
  and `init.lua` — a parser regression on `unresolved verbose` is
  half-fixed in two places.
- **Testability.** A is the design that makes the parent's
  acceptance criterion "every parser has at least one passing unit
  test" verifiable through the layer's interface alone, with no test
  reaching past a seam. B's parsers are smaller and more generic; the
  per-subcommand mutation point lives in `init.lua` where the shell
  seam has to be exercised. PRD goal #1 directly mandates A.
- **Goal #2 (parsers free of shell side effects).** A satisfies
  cleanly. B blurs the boundary by leaving leaf glue in `init.lua`
  alongside the shell-invoking compositions.

### Chosen: A

A is the design the PRD's goals already point at. B was generated to
satisfy design-it-twice, not because it is competitive — it would
push the per-subcommand parse logic into `init.lua` and defeat the
"thin compositions" goal. Recording the trade-off here so future
readers know B was considered and why.

### Sample composition (illustrative — exact form decided in implementation)

```lua
-- init.lua
function M.tasks_to_quickfix(opts)
  local cmdline = command.tasks(opts)
  local lines, err = shell.run(cmdline)
  if not lines then return false, err end
  local items = parsers.tasks_verbose(lines)
  return presenter.to_quickfix(
    (opts and opts.only_todo == false) and "Obsidian Tasks" or "Obsidian Tasks (todo)",
    items
  )
end
```

The four-call shape is the surface every leaf converges to. Where a
leaf currently does extra work (e.g. `bookmarks_list_verbose`'s
keymap on the scratch buffer, `toggle_task_from_quickfix`'s reload),
that work lives in `init.lua` after the four-call pipeline returns —
not inside any layer.

## Acceptance criteria

- [ ] Directory `lua/utils/obsidian_cli/` exists with files
      `init.lua`, `command.lua`, `shell.lua`, `parsers.lua`,
      `presenter.lua`. The pre-cycle `lua/utils/obsidian_cli.lua` is
      deleted (so `require("utils.obsidian_cli")` resolves to
      `init.lua`).
- [ ] `init.lua` exports the same 14 `M.*` function names that
      `lua/utils/obsidian_cli.lua` exported, with the same argument
      shapes. Verified by the tracer spec.
- [ ] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is
      empty.
- [ ] `grep -rn 'systemlist\|os\.execute\|io\.popen' lua/utils/obsidian_cli/`
      returns exactly one match — inside `shell.lua`.
- [ ] `shell.lua` exposes `set_runner(fn)` and `reset_runner()`. The
      default runner wraps `vim.fn.systemlist` and is in effect on
      module load.
- [ ] `parsers.lua` and `command.lua` contain zero references to
      `vim.fn.systemlist`, `os.execute`, `io.popen`, or any
      shell-execution primitive. Verified by grep.
- [ ] `command.lua` exposes one builder per non-trivial subcommand
      that a future sub-issue will write a builder test for —
      including the shell-escape case (`search:context`).
- [ ] The tracer spec at `tests/utils/obsidian_cli/init_spec.lua`
      passes under `./tests/run`, asserting all 14 `M.*` names exist
      and are of `type == "function"`.
- [ ] `./tests/run` exits 0 on the whole suite — this sub-issue's
      tracer plus cycle 01's `tests/utils/wordcount_spec.lua`.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0. No shell call to
      `obsidian` happens at module load or during the tracer.
- [ ] No reaching into local functions or monkey-patching globals in
      the tracer spec. Carry-forward acceptance criterion from cycle
      01.

## Proposed tests

| Title                                               | What it verifies                                                                                                       |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| tracer: module loads through the directory          | `require("utils.obsidian_cli")` resolves and returns a table. First Contact check for the layout.                      |
| tracer: all 14 `M.*` names are functions            | Iterate the expected 14 names, assert each is `type == "function"`. Catches a missed export during the move.            |
| smoke: `shell.set_runner` / `shell.reset_runner` exist and are callable | The seam is wired. Calling `set_runner(function() return {}, nil end)` then `reset_runner()` is a no-op trip. |

The first two are the real tracer (Stage 2's First Contact). The
third is a smoke check that the seam is in place — minimal, no parser
or composition exercised. Future sub-issues replace this with real
behavior tests.

A **deliberate-failure verification** is run once during
implementation (rename one of the 14 exports, confirm the tracer
goes red, revert) and recorded in the AAR. Not a committed spec.

## Affected artifacts

- New: `lua/utils/obsidian_cli/init.lua`
- New: `lua/utils/obsidian_cli/command.lua`
- New: `lua/utils/obsidian_cli/shell.lua`
- New: `lua/utils/obsidian_cli/parsers.lua`
- New: `lua/utils/obsidian_cli/presenter.lua`
- Deleted: `lua/utils/obsidian_cli.lua`
- New: `tests/utils/obsidian_cli/init_spec.lua` (the tracer)
- Unchanged: `lua/config/commands.lua` (verified by `git diff`)
- Unchanged: `tests/utils/wordcount_spec.lua`, `tests/init.lua`,
  `tests/run`

No fixture files yet — those land per-parser in #15+.

## Dependencies

None. This is the first sub-issue of parent #13.

## Out of scope (deferred to #15+)

- Any parser unit test against captured CLI output. The tracer
  exercises the shape of the move, not parser behavior.
- Any command-builder unit test, including the shell-escape case for
  `search:context`. The builder exists in `command.lua` from this
  sub-issue forward; the test that exercises it is a #15+ slice.
- Any presenter test. Presenter testability assessment (PRD open
  question #3) is itself a future sub-issue.
- Any decision on ADR-0003. The four-layer pattern's durability is
  evaluated after at least one parser-pass sub-issue closes.
- Reshaping `extract_bookmark_note_path` (currently calls
  `vault_relpath_to_abs`, mixing pure parse with `vim.loop` IO).
  Move it to `parsers.lua` as-is for now; pure/impure split is a
  future slice if it becomes load-bearing.
