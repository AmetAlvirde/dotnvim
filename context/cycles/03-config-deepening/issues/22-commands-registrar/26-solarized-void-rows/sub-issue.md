# Sub-issue — Solarized commands migration with void-return shape

GitHub issue: #26. Fourth sub-issue of parent #22, after #23's
tracer, #24's no-arg ObsCLI batch, and #25's `nargs`-bearing ObsCLI
batch. Migrates the three `Solarized*` user commands onto
`commands.register`. Introduces exactly one new spec-row shape
decision: a `kind = "void"` variant that lets the registrar accept
leaves which do not return the `(success, msg)` envelope. Resolves
the parent #22 deferred decision on void-return modelling
(documented in parent `issue.md` "Implementation approach" as the
three-option choice between `kind = "void"`, a separate
`commands.register_void`, and tiny `(true, "")` adapters). The
chosen shape — `kind = "void"` — is recorded under "Interface
design" below with the reason for rejecting the other two.

## Description

Migrate three user commands in `lua/config/commands.lua` from their
inline `vim.api.nvim_create_user_command(..., function() ...
require("colors.solarized").<fn>() end, { desc = ... })` shape onto
`commands.register({ ... })` spec rows:

| Command | Leaf | `args` shape (post-migration) | `kind` |
| --- | --- | --- | --- |
| `SolarizedToggle` | `colors.solarized.toggle()` | none | `"void"` |
| `SolarizedDark` | `colors.solarized.set_theme("dark")` | `function(_) return { "dark" } end` | `"void"` |
| `SolarizedLight` | `colors.solarized.set_theme("light")` | `function(_) return { "light" } end` | `"void"` |

All three leaves return whatever `set_theme` / `toggle` happen to
return today (currently nothing observable from the call sites). The
registrar's `kind = "void"` branch discards the return value and
emits no notify on success.

Add `kind = "void"` handling to `lua/config/commands_registrar.lua`.
The branch sits after `pcall(require)` and after `args` evaluation
but before the `(success, msg)` unpacking; load-failure handling
stays identical for void rows. The five existing callback branches
(load failure, leaf failure, leaf success silent, leaf success
silent-nil, leaf success with message) remain unchanged for spec
rows that omit `kind`.

A side effect of the migration: `pcall(require, "colors.solarized")`
now wraps each Solarized command's load. Pre-migration, a load
failure of `colors.solarized` would surface as an uncaught Lua error
when the user invoked `:SolarizedToggle` (et al.). Post-migration,
it surfaces as an ERROR-level `vim.notify("Failed to load
colors.solarized")`. This is a behavior *improvement*, not a
regression — the parent #22 user story "register one row, not
fourteen lines" implicitly bundles uniform load-failure handling.
Recorded under "Interface design" so the AAR captures the
intentional change.

Add new cases to `tests/config/commands_registrar_spec.lua`
covering: a `kind = "void"` row calls the leaf and emits no notify
on success; a `kind = "void"` row whose leaf returns something
(even a tuple) still emits no notify; the load-failure branch still
fires for `kind = "void"` rows. Existing seven cases from #23 plus
the two `nargs` cases from #25 stay unchanged.

`commands.lua` retains its current section-comment structure and
ordering; only the three `Solarized*` blocks change shape. The
remaining 3 inline commands (`ObsCLISearchContext`, `WordCount`,
`ObsCLIWordCount`) stay byte-for-byte unchanged. They migrate in
subsequent sub-issues.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `commands.register` | In-process (owned, this cycle) | Edited in this sub-issue. The added `kind = "void"` branch is covered by new spec cases. The unchanged `(success, msg)` branches are covered by the seven cases from #23 plus the two `nargs` cases from #25. |
| `colors.solarized` (`toggle`, `set_theme`) | In-process (consumer-side, owned) | Public surface unchanged — parent #22 forbids edits to it. Migration is pass-through; the leaves are called with the same arguments they receive today. |
| `vim.api.nvim_create_user_command` | In-process (Neovim API) | Reached via `commands.register` only. The new `kind = "void"` rows produce a recorded call with the same `opts.desc` shape as `(success, msg)` rows. |
| `vim.notify` | In-process (Neovim API) | Reached via `commands.register` only. The void branch emits zero notifies on success; load-failure path is unchanged. |
| `mini.test` | In-process (test runner) | Existing harness from cycle 01. New cases live under `tests/config/commands_registrar_spec.lua`. |

No new seam introduced. The registrar gains one new spec-row key
(`kind`) with one defined value (`"void"`).

## Interface design

This sub-issue makes one registrar shape decision. Three
alternatives, drawn from the parent #22 "Implementation approach"
section.

### Alternative A — `kind = "void"` spec variant

Add an optional `kind` key to the spec row. When `kind == "void"`,
the registrar calls the leaf and discards the return; no notify
fires on success. When `kind` is absent (the default for all 12
already-migrated rows), the registrar enforces the `(success, msg)`
envelope.

```lua
local function register(spec)
  local opts = { desc = spec.desc }
  if spec.nargs ~= nil then opts.nargs = spec.nargs end
  vim.api.nvim_create_user_command(spec.name, function(cmd_opts)
    local ok, mod = pcall(require, spec.module)
    if not ok then
      vim.notify(
        spec.on_load_error or ("Failed to load " .. spec.module),
        vim.log.levels.ERROR
      )
      return
    end
    local args = spec.args and spec.args(cmd_opts) or {}
    if spec.kind == "void" then
      mod[spec.fn](unpack(args))
      return
    end
    local success, msg = mod[spec.fn](unpack(args))
    if not success then
      vim.notify(msg, vim.log.levels.ERROR)
      return
    end
    if msg and msg ~= "" then
      vim.notify(msg, vim.log.levels.INFO)
    end
  end, opts)
end
```

One spec key with one declared value. Future `kind` values (e.g.,
`"range_synthesized_notify"` for `WordCount`) compose by adding
another branch — but each new value is its own decision, in its own
sub-issue.

### Alternative B — Separate `commands.register_void(spec)` entry point

Two top-level functions. `register` enforces `(success, msg)`;
`register_void` calls the leaf and discards the return.

```lua
M.register      = function(spec) ... end  -- (success, msg) shape
M.register_void = function(spec) ... end  -- void shape
```

Each Solarized row would call `register_void({...})` instead of
`register({...})`.

### Alternative C — Tiny `(true, "")` adapters

Wrap each Solarized leaf in a local helper that returns
`(true, "")`, then register the helper as `fn`.

```lua
-- In commands.lua
local function _solarized_toggle()
  require("colors.solarized").toggle()
  return true, ""
end
register({ name = "SolarizedToggle", desc = "...", module = ?, fn = ? })
```

This option requires either:
- editing `colors.solarized` to add adapter functions there
  (forbidden by parent #22 constraint #2), or
- placing adapters somewhere addressable by `module` / `fn` — a new
  module under `lua/config/` or `lua/utils/`, or a hack passing a
  pre-loaded table through `package.loaded`.

### Comparison

- **Leverage.** A and B are the same functional capability. C is
  the same too, but with adapter-shaped overhead. A keeps every
  Solarized row a one-table-literal call; B splits registrations
  across two functions; C requires inventing an adapter home.
- **Locality.** A keeps `commands.lua` reading top-to-bottom as a
  flat list of `register({...})` calls — story 3 of the sub-PRD
  (declarative spine) stays intact for all 18 rows. B introduces a
  second registration shape that maintainers have to grep for. C
  introduces adapter-module discovery as an extra hop.
- **Testability.** A adds one new branch to the existing
  registrar's callback. B adds a second public function — two test
  surfaces. C tests the adapter and the registrar separately.
- **Future-proofing.** `WordCount` will introduce *another* shape
  (custom-notify from a non-tuple-returning leaf). Under A, that
  becomes another `kind` value (e.g., `"range_synthesized_notify"`)
  composed into the same `register` function. Under B, that becomes
  a *third* entry point. A's growth pattern is one branch per shape;
  B's is one function per shape.
- **Constraint compliance.** A and B comply with parent #22 "no
  edits to `lua/colors/solarized.lua`'s public surface". C in its
  cleanest form (adapters in `solarized.lua`) violates it; in its
  workaround forms (separate adapter module, `package.loaded`
  injection) it adds machinery for no payoff over A.

### Chosen: A

Reason for rejecting B: B trades one registrar branch for a second
top-level function and a second test surface. The cycle's principle
— "one declarative list, one registration mechanism" (sub-PRD story
3) — is preserved by A, broken by B.

Reason for rejecting C: C either violates parent #22 constraint #2
(no edits to `colors.solarized`) or adds an adapter-module hop with
no payoff. The Solarized leaves are not the only void-returning
candidate the registrar will see — `WordCount` is coming next — and
C does not generalize cleanly to that case.

This is the resolution of parent #22 "Implementation approach"
deferred decision on void-return modelling. Recorded in parent
`issue.md` once this sub-issue closes.

### Spec-row schema after this sub-issue

```lua
register({
  name          = "...",   -- required, forwarded as user-command name
  desc          = "...",   -- required, becomes opts.desc
  module        = "...",   -- required, the leaf to require
  fn            = "...",   -- required, the key on the required module
  args          = function(cmd_opts) return { ... } end,  -- optional; default {}
  on_load_error = "...",   -- optional; defaults to "Failed to load " .. module
  nargs         = "?" | "*" | "+" | <number> | <string>,  -- optional; forwarded to opts.nargs
  kind          = "void",  -- optional; when present, leaf return is discarded
})
```

`kind`'s value space is currently the single string `"void"`. Future
shapes (e.g., `WordCount`'s synthesized-notify) will introduce
additional values — each in its own sub-issue, with its own branch
in the registrar callback.

`complete`, `range`, `bang` forwards remain deferred. `range` lands
when `WordCount` migrates.

### Behavior change recorded under interface design

Pre-migration, an `:SolarizedToggle` invocation with
`colors.solarized` failing to load surfaced an uncaught Lua error
(no `pcall`, no `vim.notify`). Post-migration, it surfaces an
ERROR-level `vim.notify("Failed to load colors.solarized")`. This
is a *behavior improvement*, intentional, and recorded here so the
AAR can confirm during the live smoke check that the new behavior
does not regress any user-visible flow. There is no realistic load-
failure scenario for `colors.solarized` in normal use; the
regression check is the smoke-check item, not a spec.

### Entry points, inputs, outputs, invariants, error modes

- **Entry point unchanged:** `commands.register(spec)`.
- **New input field:** `spec.kind` — optional; when set to
  `"void"`, the registrar's callback discards the leaf's return and
  emits no notify on success. When absent, the `(success, msg)`
  envelope is enforced as before.
- **Outputs unchanged.** No return value.
- **Invariant carry-forward:** the registrar calls
  `nvim_create_user_command` exactly once per `register` call. The
  callback never throws under any branch.
- **New invariant:** for `kind = "void"` rows, `vim.notify` is
  called exactly zero times on the success path (regardless of what
  the leaf returns), and exactly once on the load-failure path
  (same as `(success, msg)` rows).
- **Error modes:** load failure unchanged. Leaf-failure /
  leaf-success-with-message branches do not fire for `kind =
  "void"` rows — those branches are skipped entirely.

## Acceptance criteria

- [ ] Each of the three commands — `SolarizedToggle`,
      `SolarizedDark`, `SolarizedLight` — is registered through
      `commands.register` with `module = "colors.solarized"`,
      `fn` set to `toggle` or `set_theme`, `kind = "void"`, and
      (for `SolarizedDark` / `SolarizedLight`) an `args` function
      returning `{ "dark" }` or `{ "light" }`.
- [ ] Each migrated row preserves its `desc` string verbatim from
      the pre-migration inline block.
- [ ] `lua/config/commands_registrar.lua` honors `spec.kind ==
      "void"` by calling the leaf with unpacked args and returning
      without unpacking a `(success, msg)` tuple. The branch sits
      after `pcall(require)` and `args` evaluation but before the
      `(success, msg)` unpacking. Other rows (no `kind` key) behave
      exactly as before.
- [ ] After migration, `lua/config/commands.lua` contains zero
      direct calls to `vim.api.nvim_create_user_command` for any
      of the three migrated commands. Verified by
      `grep -n 'nvim_create_user_command(\"\(SolarizedToggle\|SolarizedDark\|SolarizedLight\)\"' lua/config/commands.lua`
      returning zero matches.
- [ ] After migration, `lua/config/commands.lua` contains zero
      direct `require("colors.solarized")` calls outside of any
      `args` or `register` argument expression. (The `module =
      "colors.solarized"` string in a spec row does not count as a
      direct require — the registrar performs the `pcall(require)`
      at command-invocation time.)
- [ ] The 3 commands not migrated in this sub-issue —
      `ObsCLISearchContext`, `WordCount`, `ObsCLIWordCount` — are
      byte-for-byte unchanged from pre-sub-issue state. Verified
      by `git diff` on `commands.lua` showing edits only inside
      the three migrated `Solarized*` blocks (plus possible
      whitespace/section-comment adjustments adjacent to them).
- [ ] No edits to `lua/colors/solarized.lua` — the public surface
      (`set_theme`, `toggle`) is consumed unchanged. Verified by
      `git diff` showing no changes to that file.
- [ ] No edits to `lua/utils/obsidian_cli/` (any file) or
      `lua/utils/wordcount.lua`. Their public surfaces are not
      touched in this sub-issue.
- [ ] `tests/config/commands_registrar_spec.lua` gains at least
      three new cases:
      1. a `kind = "void"` row calls the leaf with unpacked args
         and emits zero notifies;
      2. a `kind = "void"` row whose leaf returns a tuple-shaped
         value still emits zero notifies (the return is discarded);
      3. a `kind = "void"` row whose `module` fails to load still
         emits one ERROR-level notify with the load-failure message.
- [ ] All nine inherited cases (seven from #23, two from #25) in
      `tests/config/commands_registrar_spec.lua` still pass
      unchanged. The new cases do not delete or weaken any existing
      assertion.
- [ ] `./tests/run` exits 0 on the whole suite — including all
      cycle 01 specs, cycle 02 specs, and the registrar spec with
      its new `kind = "void"` cases.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent —
      the suite passes with `obsidian` and `codesign` absent from
      `$PATH`).
- [ ] Live smoke check — recorded in the AAR, not a committed
      spec — invokes each of the three migrated commands inside
      Neovim and confirms observable behavior matches
      pre-migration: `:SolarizedToggle` flips between dark and
      light; `:SolarizedDark` activates dark; `:SolarizedLight`
      activates light. No spurious notifies fire on the success
      path.
- [ ] `wc -l lua/config/commands.lua` is strictly less than the
      pre-sub-issue line count (259). The <120-line target for
      parent #22 closure is approached but not necessarily reached
      by this sub-issue alone.
- [ ] Parent `issue.md` records the resolution of the void-return
      decision (Alternative A — `kind = "void"`) in its
      "Implementation approach" section, replacing the open-ended
      three-option discussion with the chosen shape and a
      one-sentence rejection reason for B and C.
- [ ] No reaching into local functions or monkey-patching internals
      in the new spec cases. The new cases use the same
      `pre_case`/`post_case` API swaps from #23.
- [ ] AAR records: the registrar diff (the `kind = "void"` branch
      addition), the line-count delta on `commands.lua`, the
      live-smoke-check result for each of the three commands, the
      deliberate-failure verification result, and any flags
      surfaced for subsequent migration sub-issues.

## Proposed tests

Three new cases land in `tests/config/commands_registrar_spec.lua`.
The nine inherited cases (seven from #23 plus two from #25) stay
unchanged.

| Title | What it verifies |
| --- | --- |
| `register: kind = "void" calls leaf with unpacked args and emits no notify` | Stub leaf in `package.loaded` records its call args and returns nothing. Spec row has `kind = "void"` and `args = function(_) return { "dark" } end`. After invoking the recorded callback, assert leaf called once with `("dark")` and zero notifies recorded. |
| `register: kind = "void" discards leaf return value` | Stub leaf returns `(true, "msg")` — a tuple that would emit an INFO notify under the standard envelope. Spec has `kind = "void"`. Assert zero notifies. |
| `register: kind = "void" still surfaces load failure as ERROR notify` | Spec has `kind = "void"` and `module = "utils.does_not_exist"`. Invoking the callback emits exactly one ERROR notify with the load-failure message. Confirms the void branch sits below `pcall(require)` and does not bypass load-failure handling. |

The first case is the Stage-2 First Contact for `kind = "void"`.
The second locks the discard-on-return contract. The third is the
sanity guard that void shape composes with load-failure unchanged.

A deliberate-failure verification runs once during implementation:
move the `if spec.kind == "void"` check above the `pcall(require)`
call (i.e., bypass load-failure handling for void rows). Confirm the
"void still surfaces load failure" case goes red. Revert. Recorded
in the AAR.

## Affected artifacts

- Edited: `lua/config/commands.lua` — the three `Solarized*` blocks
  are replaced by `commands.register({ ... })` spec rows in place.
  Section comment "Manual theme switching commands" preserved.
- Edited: `lua/config/commands_registrar.lua` — adds the `if
  spec.kind == "void"` branch inside the existing `register`
  function's callback. Approximately three lines added.
- Edited: `tests/config/commands_registrar_spec.lua` — adds three
  new cases (per "Proposed tests" above). No existing case is
  altered.
- Edited: parent `issue.md` — replaces the open-ended three-option
  discussion under "Implementation approach" with the chosen shape
  (Alternative A — `kind = "void"`) and a one-sentence rejection
  reason for B and C.
- Unchanged: `lua/colors/solarized.lua`. Public surface consumed,
  not edited.
- Unchanged: `lua/utils/obsidian_cli/` (any file).
- Unchanged: `lua/utils/wordcount.lua`.
- Unchanged: `tests/init.lua`, `tests/run`, all other specs.
- New: this sub-issue's `aar.md` on close.

## Dependencies

- **#23 closure** — `commands.register` exists at
  `lua/config/commands_registrar.lua` with the spec-row schema
  baseline. Already closed.
- **#24 closure** — established the per-row migration pattern
  (Alternative A, explicit `register({...})` calls per row;
  ordering and section comments preserved). Already closed.
- **#25 closure** — established the registrar-extension pattern
  (one new spec-row key per sub-issue, with corresponding new
  spec cases). This sub-issue applies the same pattern for `kind`
  that #25 applied for `nargs`. Already closed.
- **`lua/colors/solarized.lua`** — the public surface (`set_theme`,
  `toggle`) is the registration target for the three Solarized
  rows. Cycle PRD non-goal (and parent #22 constraint #2): no edits
  to that file's public surface in this cycle. Migration is
  pass-through.
- **Cycle 01 closure** — `mini.test` harness at `./tests/run`.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `26-solarized-void-rows` tracks GitHub
  issue #26.
- No dependency on any other cycle 03 sub-issue beyond #23, #24, #25.

## Out of scope (deferred to subsequent sub-issues of parent #22)

- Migration of `ObsCLISearchContext`. It surfaces a WARN-level
  early return on empty `vim.fn.input` — a different new spec-row
  shape decision (early-return signalling from `args`, or some
  equivalent contract for "abort, don't call the leaf"). That
  decision lands in its own sub-issue. The void-return shape
  introduced here does not address it; `ObsCLISearchContext`'s
  leaf returns the standard `(success, msg)` envelope, so its
  `kind` would not be `"void"`.
- Migration of `WordCount` and `ObsCLIWordCount`. `WordCount`
  introduces two new decisions: `range` forwarding (mechanical,
  similar to #25's `nargs`) and a custom synthesized notify
  message that does not flow from the leaf's return (a *third*
  shape variant — possibly `kind = "synthesized_notify"`, possibly
  some other modelling). `ObsCLIWordCount` carries `nargs = "*"`
  (already supported) but is grouped with `WordCount` per the
  parent's plan. Both migrate together.
- Adding `complete`, `range`, or `bang` forwarding to the
  registrar. `range` lands with `WordCount`. `complete` and `bang`
  land if and when a consumer needs them; otherwise they never
  land.
- Hardening the registrar against missing-`fn` calls (the
  deliberate-failure verification flag-check from #24's AAR). Not
  in scope here. If surfaced by the live smoke check on the
  Solarized rows (e.g., `fn = "set_theme_does_not_exist"`), it
  becomes a parent #22 flag, not a fix in this sub-issue.
- Spec coverage of the `args`-calling-`vim.fn.input` pattern from
  #25. Same out-of-scope rationale as #25 carried forward.
- Candidate F (domain split of `commands.lua`) decision. Closing
  sub-issue of parent #22.
- ADR-0004 candidacy for the registrar pattern. Per cycle PRD open
  question 4, deferred until at least one more seam (Candidate B
  or D) is in place.
