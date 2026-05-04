# Parent Issue — `commands.lua` declarative dispatch (Candidate A)

GitHub issue: #22. First parent of cycle `03-config-deepening`,
landing first per the cycle PRD's resolved sequencing
(A → D → B → C). Translates `sub-prd.md` into a trackable technical
unit. The two artifacts are complementary — `sub-prd.md` records
product-level intent (user stories, scope, dependencies); this file
records the technical contract (acceptance criteria, implementation
approach, flags).

## Acceptance criteria

- [ ] A `commands.register(spec)` function exists, is publicly
      `require`-able, and is the only place in the configuration that
      calls `vim.api.nvim_create_user_command`. Verified by
      `grep -rn 'nvim_create_user_command' lua/` returning matches
      only inside the registrar module.
- [ ] `lua/config/commands.lua` becomes a list of spec rows, each fed
      to `commands.register`. The per-command
      `pcall(require, "utils.obsidian_cli")` → call → `vim.notify`
      block is gone. Verified by
      `grep -n 'pcall(require, "utils\.obsidian_cli")' lua/config/commands.lua`
      returning zero matches.
- [ ] `wc -l lua/config/commands.lua` returns under 120 lines (down
      from 366). *(Cycle PRD success metric #2.)*
- [ ] All 18 user commands currently defined in `commands.lua` —
      `SolarizedToggle`, `SolarizedDark`, `SolarizedLight`,
      `ObsCLITasks`, `ObsCLITaskToggle`, `ObsCLIOrphans`,
      `ObsCLIDeadends`, `ObsCLIUnresolved`, `ObsCLISearchContext`,
      `ObsCLIHistory`, `ObsCLIHistoryRead`, `ObsCLIDiffFrom`,
      `ObsCLIOutline`, `ObsCLIBacklinks`, `WordCount`,
      `ObsCLIWordCount`, `ObsCLIBookmarks`, `ObsCLIBookmarkAdd` —
      remain registered through the registrar with the same names
      and argument shapes (`nargs`, `complete`, `range`, `bang`).
      Verified by inspecting the spec rows against pre-cycle
      `git show` output.
- [ ] The registrar has at least one passing unit test under
      `tests/config/` (or wherever the registrar lands per resolved
      decision below) exercised by `./tests/run`. The test fakes
      `vim.api.nvim_create_user_command`, calls `commands.register`
      with a representative spec, and asserts the recorded call
      shape — name, options table, callback wiring, error and
      info handling.
- [ ] At least one registrar spec covers each of these
      observable-behavior cases: a `pcall(require, ...)` failure
      surfaces an ERROR-level `vim.notify`; a leaf returning
      `(false, msg)` surfaces an ERROR-level `vim.notify` with `msg`;
      a leaf returning `(true, msg)` with non-empty `msg` surfaces
      an INFO-level `vim.notify`; a leaf returning `(true, "")` or
      `(true, nil)` surfaces no notify.
- [ ] No edits to `lua/utils/obsidian_cli/` (any file),
      `lua/utils/wordcount.lua`, or the public surface of
      `lua/colors/solarized.lua` (`set_theme`, `toggle`). Verified
      by `git diff <cycle-base>..HEAD -- <those paths>` being empty.
- [ ] `./tests/run` exits 0 on the whole suite — including all cycle
      01 and cycle 02 specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `obsidian` and `codesign` absent from
      `$PATH`).
- [ ] No reaching into local functions or monkey-patching internals
      anywhere in the new specs. Carry-forward acceptance criterion
      from cycles 01 and 02, still binding.
- [x] **Resolved-through-implementation decision recorded:**
      registrar location → `lua/config/commands_registrar.lua`.
      Reason: lowest-friction option that is `require`-able and
      testable in isolation without top-level side-effects from
      `commands.lua`. Promotion to `lua/utils/` deferred until a
      second consumer surfaces (none in cycle 03 scope). Spec-row
      schema confirmed as Alternative A (keys: `name`, `desc`,
      `module`, `fn`; optional `args`, `on_load_error`; optional
      forwards `nargs`/`complete`/`range`/`bang` deferred).
      Recorded in sub-issue #23 AAR. First sub-issue closed.
- [ ] **Resolved-through-implementation decision recorded:** whether
      Candidate F (domain split of `commands.lua` by `solarized` /
      `obsidian_cli` / `wordcount`) lands as a closing sub-issue or
      is skipped. Recorded in this file with a one-sentence reason.

## Implementation approach

### Registrar interface (sketch — final shape decided in first sub-issue)

```lua
-- commands.register(spec)
-- spec = {
--   name = "ObsCLITasks",                      -- required
--   desc = "List Obsidian TODO tasks…",        -- required
--   nargs = "?",                               -- optional, forwarded to user_command opts
--   complete = function(...) end,              -- optional, forwarded
--   range = false,                             -- optional, forwarded
--   bang = false,                              -- optional, forwarded
--   module = "utils.obsidian_cli",             -- required
--   fn = "tasks_to_quickfix",                  -- required (string key on the required module)
--   args = function(opts) return { only_todo = true } end,  -- optional; default no-args
--   on_load_error = "Failed to load utils.obsidian_cli",     -- optional override
-- }
```

The registrar:

1. Registers via `vim.api.nvim_create_user_command(spec.name, cb, opts)`
   where `opts` is the subset `{ desc, nargs, complete, range, bang }`
   filtered from the spec, and `cb` is a closure that:
2. `pcall(require, spec.module)` — on failure, ERROR-level
   `vim.notify(spec.on_load_error or "Failed to load " .. spec.module)`,
   return.
3. Resolves `args` from `spec.args(opts)` if provided, else `{}`.
4. Calls `module[spec.fn](unpack(args))`.
5. Inspects the return shape `(success, msg)`:
   - `success == false`: ERROR-level `vim.notify(msg)`.
   - `success == true` and `msg ~= "" and msg ~= nil`: INFO-level
     `vim.notify(msg)`.
   - else: no notify.

The Solarized commands use a thinner shape — they call into
`colors.solarized.set_theme("dark")` / `toggle()` and do not return
the `(success, msg)` envelope. Decide in the first sub-issue whether
to model these via a `kind = "void"` spec variant, a separate
`commands.register_void(spec)` entry point, or by accepting that
`set_theme` and `toggle` are wrapped in tiny adapters that return
`(true, "")`. Record the choice here once landed.

### Layout (resolved in sub-issue #23)

**Chosen: `lua/config/commands_registrar.lua`** (option 1).

`commands.lua` does `local register = require("config.commands_registrar").register`
and feeds it spec rows. The registrar is `require`-able and testable
in isolation without top-level side effects from `commands.lua`.
Option 2 (local table) was rejected because a local function cannot be
exercised by a spec without monkey-patching `commands.lua`'s top-level
state. Option 3 (promote to `lua/utils/`) is deferred until a second
consumer surfaces; none exists in cycle 03 scope.

### Test pattern (the seam this parent issue establishes for B and D)

The registrar is testable without a live Neovim editing session.
The pattern:

1. In `pre_case`, swap `vim.api.nvim_create_user_command` for a
   fake that records `(name, callback, opts)` into a per-test table.
2. Call `commands.register(spec)` with a representative row.
3. Assert the recorded `(name, opts)` matches the spec.
4. Invoke the recorded callback with a synthesized `opts` argument
   to exercise the `pcall(require)` / call / notify branches. Stub
   `vim.notify` similarly to record level and message.
5. In `post_case` (or `mini.test.finally`), restore the originals.

No `mini.test.new_child_neovim`. No reaching into module-locals.
The registrar is the seam; everything tests through it.

This pattern is the exact shape Candidate B will use to test its
`subscribe` registrar, and Candidate D will use to test its autocmd
binding. A is responsible for proving it works.

### Sequencing

Per the cycle 01 process spec — Stage 1 tracer → Stages 2–3
incremental TDD → Stage 4 deepen — this parent issue maps to:

- **First sub-issue (#23+):** tracer slice. Build `commands.register`
  in its chosen location with the minimum interface that registers
  one ObsCLI command (e.g. `ObsCLITasks` — the simplest no-arg
  shape). Add the first registrar spec exercising registration,
  load-failure, and `(true, "")` return. Migrate `ObsCLITasks` in
  `commands.lua` to use the registrar; leave the other 17 commands
  on the old shape. Resolve the registrar-location and spec-schema
  decisions in this sub-issue's AAR. `./tests/run` green.

- **Subsequent sub-issues:** migrate the remaining commands in
  groups, picking the grouping that surfaces the smallest set of new
  spec-row shape decisions per sub-issue. Rough groupings (final
  sequencing decided per sub-issue, informed by prior AARs):

  - The remaining no-arg ObsCLI commands sharing the
    `(success, msg)` envelope.
  - The `nargs`/`complete`-bearing ObsCLI commands
    (`ObsCLIHistoryRead`, `ObsCLIDiffFrom`, `ObsCLIOutline`,
    `ObsCLIBacklinks`, `ObsCLIBookmarkAdd`).
  - The Solarized commands — once the void-return shape is decided.
  - The two WordCount commands.

- **Closing sub-issue:** Candidate F decision. Either land the
  domain split of `commands.lua` (if the registered list is no
  longer scannable as one file) or record a one-sentence
  skip-reason in this `issue.md` and the sub-issue's AAR.

Sub-issue numbering follows ADR-0002 — sequential GitHub issue
numbers, not cycle-local numbers.

### Constraints binding the implementation

1. The 18 user commands keep their names and argument shapes. No
   command is added, renamed, or removed in this parent issue.
2. No edits to `lua/utils/obsidian_cli/`, `lua/utils/wordcount.lua`,
   or the public surface of `lua/colors/solarized.lua`.
3. Tests exercise public interfaces only. No reaching into locals,
   no monkey-patching internals beyond the per-test
   `vim.api.nvim_create_user_command` and `vim.notify` swaps that
   the registrar's interface explicitly invites.
4. The test suite runs to green with `obsidian` absent from `$PATH`
   — the registrar's load-failure branch must not require
   `utils.obsidian_cli` to load successfully.
5. No new plugin dependencies. `mini.test` from cycle 01 remains
   the only test tooling.

## Dependencies

- **Cycle 01 closure** — `mini.test` harness in place at
  `./tests/run`, `tests/init.lua` bootstrap with the `os.exit(0)`
  short-circuit preserved. Already closed.
- **Cycle 02 closure (parent #13)** — the 14 `M.*` functions on
  `lua/utils/obsidian_cli/init.lua` are the registration target for
  all 13 ObsCLI rows. Already closed.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `22-commands-registrar` tracks GitHub
  issue #22; sub-issues take sequential GitHub numbers.
- No dependency on any other cycle 03 parent. A is the first
  parent in the resolved sequencing; B and D depend forward on A's
  test pattern but A does not depend on them.

## Flags

*None yet. Sub-issue AARs surface flags as they appear.*
