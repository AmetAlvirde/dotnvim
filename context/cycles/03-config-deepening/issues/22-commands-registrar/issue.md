# Parent Issue — `commands.lua` declarative dispatch (Candidate A)

GitHub issue: #22. First parent of cycle `03-config-deepening`,
landing first per the cycle PRD's resolved sequencing
(A → D → B → C). Translates `sub-prd.md` into a trackable technical
unit. The two artifacts are complementary — `sub-prd.md` records
product-level intent (user stories, scope, dependencies); this file
records the technical contract (acceptance criteria, implementation
approach, flags).

## Acceptance criteria

- [x] A `commands.register(spec)` function exists, is publicly
      `require`-able, and is the only place in **`lua/config/`** that
      calls `vim.api.nvim_create_user_command`. Verified by
      `grep -rn 'nvim_create_user_command' lua/config/` returning matches
      only inside `lua/config/commands_registrar.lua`. Scope amended in
      sub-issue #28: `lua/plugins/lualine.lua` contains a plugin-internal
      `LualineRefresh` user command (a closure over plugin state with no
      leaf module) that is out-of-contract for this parent issue.
      Verified output: `lua/config/commands_registrar.lua:7:
      vim.api.nvim_create_user_command(spec.name, …)`.
- [x] `lua/config/commands.lua` becomes a list of spec rows, each fed
      to `commands.register`. The per-command
      `pcall(require, "utils.obsidian_cli")` → call → `vim.notify`
      block is gone. Verified by
      `grep -n 'pcall(require, "utils\.obsidian_cli")' lua/config/commands.lua`
      returning zero matches (grep exit 1, no output).
      Structural-intent AC preserved; line-budget AC removed in #28 —
      line counts do not shape the contract.
- [x] All 18 user commands currently defined in `commands.lua` —
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
- [x] The registrar has at least one passing unit test under
      `tests/config/` (or wherever the registrar lands per resolved
      decision below) exercised by `./tests/run`. The test fakes
      `vim.api.nvim_create_user_command`, calls `commands.register`
      with a representative spec, and asserts the recorded call
      shape — name, options table, callback wiring, error and
      info handling.
      Verified: `tests/config/commands_registrar_spec.lua` — 18 cases,
      all green. Suite total: 110 cases, 5 groups.
- [x] At least one registrar spec covers each of these
      observable-behavior cases: a `pcall(require, ...)` failure
      surfaces an ERROR-level `vim.notify`; a leaf returning
      `(false, msg)` surfaces an ERROR-level `vim.notify` with `msg`;
      a leaf returning `(true, msg)` with non-empty `msg` surfaces
      an INFO-level `vim.notify`; a leaf returning `(true, "")` or
      `(true, nil)` surfaces no notify.
      Verified: all four branches covered in `commands_registrar_spec.lua`.
- [x] No edits to `lua/utils/obsidian_cli/` (any file),
      `lua/utils/wordcount.lua`, or the public surface of
      `lua/colors/solarized.lua` (`set_theme`, `toggle`). Verified
      by `git diff c124f97..HEAD -- <those paths>` being empty.
      Cycle base: `c124f97` (merge PR #21, pre-cycle-03 state).
      All three diffs empty.
- [x] `./tests/run` exits 0 on the whole suite — including all cycle
      01 and cycle 02 specs.
      Verified: exit 0, 110 cases, 0 fails, 0 notes.
- [x] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `obsidian` and `codesign` absent from
      `$PATH`).
      Verified: `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exits 0
      (nvim lives at `/opt/homebrew/bin/nvim`; `obsidian` and `codesign`
      excluded). 110 cases, 0 fails.
- [x] No reaching into local functions or monkey-patching internals
      anywhere in the new specs. Carry-forward acceptance criterion
      from cycles 01 and 02, still binding.
      Verified: all registrar specs use the public `register` surface;
      no locals accessed.
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
- [x] **Resolved-through-implementation decisions recorded (sub-issue
      #28):**
      **Candidate F** (domain split of `commands.lua` by `solarized` /
      `obsidian_cli` / `wordcount`) — **skip**. Post-#27 `commands.lua`
      is a flat list of spec rows under preserved section comments,
      scannable as one declarative file; no second pressure point (19th
      command, second registrar consumer, real ergonomic friction) has
      surfaced.
      **ADR-0004** (registrar pattern) — **defer to cycle 03 close**.
      The registrar is currently a single-consumer pattern; after at
      least one of Candidates B / D lands, the pattern's ADR-worthy
      invariants are visible from two seams, enabling one ADR covering
      the family rather than a registrar-specific ADR that would need
      superseding.

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
the `(success, msg)` envelope. Resolved in sub-issue #26: the
registrar accepts an optional `kind = "void"` spec-row key; when
set, the callback calls the leaf and discards the return without
unpacking any `(success, msg)` tuple. Alternative B (a separate
`register_void` entry point) was rejected because it would break the
single-registration-mechanism principle and grow test surface per
shape. Alternative C (tiny `(true, "")` adapters) was rejected
because it either violates the no-edits-to-solarized.lua constraint
or adds adapter-module machinery with no payoff over A.

Three additional shape decisions resolved in sub-issue #27:

**Decision 1 — Abort-from-`args` shape** (for `ObsCLISearchContext`'s
WARN-level early return on empty prompt input). Chosen: Alternative A —
`args` may return `(nil, msg, level)` to abort the dispatch with one
notify; registrar inspects the multi-value return after evaluating
`spec.args`. Alternative B (separate `validate` callback) was rejected
because it bifurcates into two callbacks what is one decision ("should
the leaf run?") and `args` is already the entry point for that
decision. Alternative C (specialised `prompt` field) was rejected
because it only fits the prompt-then-validate case; the generic
abort-tuple mechanism covers prompt, range-required, and any future
abort shape with one branch.

**Decision 2 — `range` forwarding** (for `WordCount`'s `range = true`).
Chosen: Alternative A — one conditional `if spec.range ~= nil then
opts.range = spec.range end`, mirroring the existing `nargs` line.
Alternative B (forward `complete`, `range`, `bang` all at once) was
rejected because parent #22 explicitly defers `complete` and `bang`
until a consumer needs them; adding their forwards now means three new
test cases for branches no production row exercises.

**Decision 3 — `kind = "synthesized_notify"` shape** (for `WordCount`'s
custom INFO message synthesized from the leaf's return plus `cmd_opts`).
Chosen: Alternative A — new `kind` value plus an optional `notify =
function(returns, cmd_opts)` callback. Alternative B (inline adapter
wrapping the leaf) was rejected because its clean form violates the
no-edits-to-wordcount.lua constraint and its workaround forms add
adapter-module machinery with no payoff. Alternative C
(presence-of-`notify` as the discriminator, without a new `kind` value)
was rejected because it makes `kind` and `notify`-presence two parallel
discriminators, raising cross-product questions (e.g., `kind = "void"`
plus `notify = fn`); keeping `kind` as the single discriminator
preserves mutual exclusivity across branches.

Spec-row schema after sub-issue #27:

```lua
register({
  name          = "...",   -- required
  desc          = "...",   -- required
  module        = "...",   -- required
  fn            = "...",   -- required
  args          = function(cmd_opts)
                    -- single-table return → normal flow
                    -- (nil, msg, level) → abort with notify
                  end,                                            -- optional; default {}
  on_load_error = "...",                                          -- optional
  nargs         = "?" | "*" | "+" | <number> | <string>,          -- optional
  range         = true | <integer> | <string>,                    -- optional; forwarded to opts.range
  kind          = "void" | "synthesized_notify",                  -- optional
  notify        = function(returns, cmd_opts) return msg, level end,
                                                                  -- optional; used with kind = "synthesized_notify"
})
```

`complete` and `bang` forwards remain deferred. Every user command in
`commands.lua` is now registered through `commands.register`; zero
direct `vim.api.nvim_create_user_command` calls remain.

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
