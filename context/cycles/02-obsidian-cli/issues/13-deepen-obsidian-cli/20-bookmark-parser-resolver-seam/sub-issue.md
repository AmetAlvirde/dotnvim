# Sub-issue — bookmark-parser slice + resolver seam on `parsers.lua`

GitHub issue: #20 (folder slug per ADR-0002 — confirm at activation; rename if
the actual issue gets a different number). Seventh sub-issue of parent #13. The
sixth and final parser-pass slice after #15 (`search_context`), #16 (`paths`),
#17 (`tasks_verbose`), #18 (`unresolved_verbose`), and #19 (`backlinks_json`).
Lands the unit tests for `parsers.extract_bookmark_note_path` (the bookmark
TSV cell-picker) and introduces a small dependency-injection seam on
`parsers.lua` — `M.set_resolver(fn)` / `M.reset_resolver()` — that mirrors the
`shell.set_runner` / `shell.reset_runner` pattern established by #14.

Engages and resolves the **bookmark-parser flag**
(`#14 AAR → bookmark-parser sub-issue`) on the parent's open-flag list. The
flag's pre-document requirement is satisfied by the testing-strategy choice
recorded in the *Interface design / scope* section below: **Option B (DI
resolver seam)** is selected; Options A and C are explicitly rejected with
reasoning. The flag is **fully resolved** by this slice.

Closes the last open item of the parent's parser-coverage criterion ("every
output parser introduced or extracted by the deepening has at least one
passing unit test") — `extract_bookmark_note_path` is the sixth and last
parser. After this slice closes, **6 of 6 parsers** have dedicated specs and
that parent criterion flips fully checked.

The backlinks-parser flag (`#14 AAR → backlinks-parser sub-issue`) remains
unchanged and partially resolved (pure-parser sub-requirement closed by #19;
integration-path sub-requirement deferred). This slice does not touch it.

## Description

Two artifacts under change:

### 1. `parsers.lua` — add a resolver seam (production code change, fix-with-test scope)

The local function `vault_relpath_to_abs` (lines 7–29) calls
`vim.loop.fs_stat` and `vim.loop.fs_realpath` on candidate paths derived from
`config.vaults.paths()`. It is the only impure surface inside `parsers.lua`
and it is reachable from exactly one parser:
`M.extract_bookmark_note_path` (lines 268–287, the call site at line 274).

The seam adds two module-level functions and one local indirection:

```lua
local function default_resolver(rel)
  return vault_relpath_to_abs(rel)
end

local current_resolver = default_resolver

function M.set_resolver(fn)
  current_resolver = fn
end

function M.reset_resolver()
  current_resolver = default_resolver
end
```

The call site in `extract_bookmark_note_path` changes from
`if vault_relpath_to_abs(cell) then` to
`if current_resolver(cell) then`. No other behavior changes. The default
resolver is in effect on module load — production callers (`init.lua` and
`commands.lua` consumers) see no behavioral difference.

`init.lua` keeps its **own** `local function vault_relpath_to_abs` (line 33)
unchanged — that copy is consumed by the bookmark-list keymap at line 328 and
is **not** a duplicate-with-the-same-source: it is a separate local in a
different module. Deepening that duplication (consolidating both copies into
a shared module) is **out of scope** for this slice and is recorded as a
deepening candidate for a future cycle.

### 2. `parsers_spec.lua` — add unit tests for `extract_bookmark_note_path`

Tests use the new resolver seam: `pre_case` injects a stub resolver
(`function() return nil end` for the disk-independent cases, or a closure
returning a fixed truthy value for the disk-dependent branch); `post_case`
restores the default. This mirrors how integration-style tests would swap
`shell.set_runner` (#14 / future presenter slice).

The function under test:

```lua
function M.extract_bookmark_note_path(line)
  line = line or ""
  local cells = vim.split(line, "\t", { plain = true })
  for _, cell in ipairs(cells) do
    cell = vim.trim(cell):gsub("^[\"'](.*)[\"']$", "%1")
    if cell ~= "" and not cell:match("^https?:") then
      if current_resolver(cell) then  -- post-seam form
        return cell
      end
      if cell:match("%.md$") then
        return cell
      end
    end
  end
  local md = line:match("([%w%-%._/]+)%.md")
  if md then
    return md .. ".md"
  end
  return nil
end
```

Observable behaviors covered:

1. **`nil` input → `nil`.** No cells, no fallback regex match.
2. **Empty string input → `nil`.** Single empty cell, no fallback match.
3. **Single unquoted `.md` cell → cell returned verbatim.**
4. **Single double-quoted `.md` cell → quotes stripped, cell returned.**
5. **Single single-quoted `.md` cell → quotes stripped, cell returned.**
6. **`http://`-prefixed cell → skipped.** Falls to next cell or fallback.
7. **`https://`-prefixed cell → skipped.** Same fallthrough.
8. **TSV with title + path: first `.md` cell wins.** Title cell (no `.md`,
   resolver returns nil) is skipped; second cell is returned.
9. **Empty / whitespace-only cells skipped.**
10. **Resolver returns truthy for a non-`.md` cell → that cell is returned.**
    Stubbed resolver returns truthy for the specific input; this exercises
    the first-branch return (the disk-resolution path).
11. **Resolver returns nil for a non-`.md` cell → falls through to second
    check; cell does not end in `.md`; loop continues / fallback applies.**
12. **Fallback regex extracts `.md` substring from raw line.** When no cell
    qualifies through the loop, `line:match("([%w%-%._/]+)%.md")` extracts
    a `.md` path from the raw line and returns it. (Note the
    quirk: the captured group does **not** include the `.md` suffix because
    the pattern matches up to but not including `.md`; the function appends
    `.md` to the captured part. This is documented behavior, preserved.)
13. **No `.md` anywhere → `nil`.** Cells exhausted, fallback regex returns
    nil, function returns nil.
14. **Fixture-driven mixed-shape sample.** Captured-by-hand TSV from
    `fixtures/bookmarks_verbose.txt`, parsed line by line, expected paths
    asserted in input order.

A pre-existing branch — the title-cell-then-path-cell case — verifies that
`vim.trim` plus the outer-quote strip handles realistic bookmark output
where the title may be quoted and contain spaces.

## Dependency classification

| Dependency                                    | Category                 | Testing strategy                                                                                                                                                                       |
| --------------------------------------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `obsidian` CLI binary                         | True external (platform) | Not invoked. Specs read fixture text from disk and pass strings to the parser.                                                                                                          |
| `vim.loop.fs_stat` / `vim.loop.fs_realpath`   | True external (filesystem) | **Stubbed via the new resolver seam.** Tests inject `function() return nil end` (or a closure returning a fixed truthy value) into `parsers.set_resolver`; `pre_case` sets, `post_case` resets. No test touches the real filesystem. |
| `vim.fn.shellescape`                          | In-process (Neovim API)  | Not exercised by the parser. (Used by `command.bookmarks_verbose` in `command.lua`, not in scope here.)                                                                                  |
| `vim.fn.systemlist`                           | In-process (Neovim API)  | Not exercised. Shell seam stays untouched.                                                                                                                                              |
| `vim.split`, `vim.trim`                       | In-process (Neovim API)  | Used by the parser. No stub.                                                                                                                                                            |
| `lua/config/vaults.lua` (`VAULT_ROOTS`)       | In-process               | Loaded transitively when `parsers.lua` is required. With the stubbed resolver in effect, `VAULT_ROOTS` is **not** consulted during the test cases. The default resolver still loads it at module-import time (no behavior change there). |
| `mini.test`                                   | In-process               | Loaded via cycle 01's harness. Spec runs through `./tests/run`.                                                                                                                          |
| Captured fixture (`bookmarks_verbose.txt`)    | Test artifact            | Plain text under `tests/utils/obsidian_cli/fixtures/`, read by the spec via `io.open`+`read("*a")` then split by `\n`. Documented as captured-by-hand in the AAR.                       |

The new resolver seam is the only deviation from "shell-adapter is the only
seam" (parent's implementation-approach narrative). It is justified, scoped,
and pattern-consistent with the existing shell seam. Documented in the AAR
under "Constraint qualification."

## Interface design / scope

### Pre-activation requirement: testing strategy choice

The bookmark-parser flag on the parent issue requires that one of three
testing strategies be **explicitly chosen and justified before tests are
written**. This section discharges that requirement.

**Option A — child-Neovim + real vault files on disk.** **Rejected.**

Rationale: `parsers.lua` line 3 captures `VAULT_ROOTS = require("config.vaults").paths()`
at module load. To make `vault_relpath_to_abs` resolve a fixture path, the
test must either:

- Modify the loaded `config.vaults` module before requiring `parsers.lua`
  (monkey-patches an in-process module; violates parent constraint #3).
- Write fixture `.md` files into one of the **real** existing vault roots
  (`/Users/amet/Writing/conscium/...` or
  `/Users/amet/2025/work/.../cronicas-de-un-corredor-como-tu/...`); fragile,
  contaminates user data, requires bullet-proof cleanup, and ties the test
  to a specific developer machine.
- Spawn a child Neovim with a custom `package.path` substituting a fixture
  `config.vaults` module; possible but introduces process overhead, extra
  fixture surface area (a stub `vaults.lua`), and a layered indirection that
  does not match how the in-process specs (#15–#19) approach pure-parser
  testing.

None of these is clean. All trade clarity for filesystem realism that the
parser does not actually need to be tested honestly.

**Option B — dependency-injection seam on `parsers.lua`.** **Selected.**

Rationale (load-bearing — this is the strategy chosen for implementation):

- **Pattern-consistent.** Mirrors `shell.set_runner` / `shell.reset_runner`
  (`shell.lua` from #14). Same shape, same lifecycle (`pre_case` set,
  `post_case` reset), same default-on-load posture.
- **Pure tests.** No disk touched, no child Neovim, no fixture vault
  registration. The spec file stays under 100 lines and reads like the
  sibling parser specs.
- **No `init.lua` signature change.** Parent constraint #1 (the 14 `M.*`
  exports keep their argument shapes) is preserved. The seam is on
  `parsers.lua`, exposed as `parsers.set_resolver(fn)` and
  `parsers.reset_resolver()`. `init.lua` does not reference these — its
  bookmark-keymap callsite (line 328) uses `init.lua`'s **own** local
  `vault_relpath_to_abs` (line 33), which is a separate copy.
- **Parent constraint #3 qualification.** The narrative "the shell-adapter
  setter is the seam" was written in the parent's implementation-approach
  before this complication surfaced. The flag's existence and its explicit
  Option B suggestion implies the constraint is amenable to extension. The
  AAR records the qualification: there are now **two** test seams, both
  setter-based, both default to the real implementation, both are
  module-level functions on the layered module that owns the impure
  dependency. No globals are monkey-patched and no in-process modules are
  reloaded by tests.
- **Fix-with-test scope, per the flag.** The flag explicitly states
  "this is a production-code change; it must be flagged as fix-with-test
  scope and noted in the AAR." Both happen here.
- **Minimal surface area.** Two new functions on `parsers.lua` (~6 lines),
  one local indirection at line 274. Zero changes to other modules.

**Option C — record a flag and defer.** **Rejected.**

Rationale: Five of six parsers already have specs; deferring would leave the
parent's parser-coverage criterion partially closed for the rest of this
cycle and propagate the bookmark-parser flag forward indefinitely. Option B
is small enough to land cleanly within this slice's constraints. Deferral
would also force the cycle's final sub-issue (ADR-0003 decision) to inherit
an unresolved flag.

### Test surface

Spec requires `utils.obsidian_cli.parsers` and calls
`parsers.extract_bookmark_note_path(line)` directly. The new cases extend the
existing `tests/utils/obsidian_cli/parsers_spec.lua` file, alphabetically
grouped after the `backlinks_json` cases.

Each case wraps in a `MiniTest.new_set` block (or uses a shared `pre_case`
on a sub-set) so the resolver stub is installed before the case body runs
and torn down after. Two sub-sets are introduced:

- **`bookmarks-no-resolver`**: `pre_case` installs
  `function() return nil end` as the resolver. All cells go through the
  `cell:match("%.md$")` second-branch. Used for cases 1–9, 11–14 (any case
  where the resolver should not influence outcome).
- **`bookmarks-with-resolver`**: `pre_case` installs a closure that returns
  truthy for a specific `cell` argument and nil otherwise. Used for case 10
  (the disk-resolution branch).

`post_case` for both calls `parsers.reset_resolver()`.

### Production code change — `parsers.lua`

Diff intent (no fix-with-test beyond what the seam requires):

```lua
-- Lines 7–29 unchanged: local function vault_relpath_to_abs(rel) ... end

-- New: lines added after vault_relpath_to_abs definition.
local function default_resolver(rel)
  return vault_relpath_to_abs(rel)
end

local current_resolver = default_resolver

function M.set_resolver(fn)
  current_resolver = fn
end

function M.reset_resolver()
  current_resolver = default_resolver
end

-- Line 274 changes from:
--   if vault_relpath_to_abs(cell) then
-- to:
--   if current_resolver(cell) then
```

`vault_relpath_to_abs` stays as a local (not exposed on `M`) — only the
resolver indirection is public.

## Acceptance criteria

- [ ] `lua/utils/obsidian_cli/parsers.lua` exposes
      `M.set_resolver(fn)` and `M.reset_resolver()`. The default resolver
      wraps the existing local `vault_relpath_to_abs`. The seam is in effect
      on module load (i.e., `parsers.extract_bookmark_note_path` behaves
      identically to its pre-seam form for any production caller that does
      not call `set_resolver`).
- [ ] `lua/utils/obsidian_cli/parsers.lua` has exactly one call site to
      `current_resolver(cell)` inside `extract_bookmark_note_path`. The
      direct `vault_relpath_to_abs(cell)` call is removed; the local
      function definition stays (still referenced by `default_resolver`).
- [ ] `tests/utils/obsidian_cli/parsers_spec.lua` is extended with the
      thirteen-plus cases listed in *Proposed tests* below. Each case is
      named explicitly (no anonymous behavior bundling). Cases that require
      the resolver stub set it via `pre_case` and reset via `post_case`
      (or `mini.test.finally`).
- [ ] `tests/utils/obsidian_cli/fixtures/bookmarks_verbose.txt` exists,
      contains a hand-curated TSV sample (a few realistic bookmark lines —
      title cell + path cell, http-prefixed cells, multi-cell rows), and is
      read by the mixed-shape spec at runtime. Read line-by-line via
      `io.open`+`read("*a")` then `vim.split(body, "\n", { plain = true })`,
      mirroring the `paths.txt` and `tasks_verbose.txt` fixtures.
- [ ] `./tests/run` exits 0 on the whole suite — the new cases plus
      everything from #14, #15, #16, #17, #18, #19, plus cycle 01's
      `wordcount_spec.lua`.
- [ ] `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run` exits 0. No shell
      call to `obsidian` happens during the new specs. (Carry-forward
      posture from #14–#19.)
- [ ] No reaching into local functions, no monkey-patching globals. The new
      cases exercise `parsers.extract_bookmark_note_path` and the new
      `parsers.set_resolver` / `parsers.reset_resolver` setters as their
      only public surface.
- [ ] `git diff <cycle-base>..HEAD -- lua/config/commands.lua` is empty
      (carry-forward from parent — this slice does not edit the consumer).
- [ ] `git diff <cycle-base>..HEAD -- lua/utils/obsidian_cli/` shows
      changes confined to `parsers.lua` and limited to: the resolver-seam
      additions (default_resolver, current_resolver, set_resolver,
      reset_resolver) and the one-line change at line 274 from
      `vault_relpath_to_abs(cell)` to `current_resolver(cell)`.
- [ ] `lua/utils/obsidian_cli/init.lua` is unchanged. Its local
      `vault_relpath_to_abs` (line 33) is not modified; its 14 `M.*`
      exports retain their argument shapes (parent constraint #1).
- [ ] After this slice closes, the parent acceptance criterion "every
      output parser introduced or extracted by the deepening has at least
      one passing unit test" is **fully checked** (6 of 6).
- [ ] The bookmark-parser flag on the parent (`#14 AAR → bookmark-parser
      sub-issue`) is closed at slice closure (the AAR records the
      strategy chosen and the seam landed).

## Proposed tests

| Title                                                                                                                                  | What it verifies                                                                                                                                                                       |
| -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `parsers.extract_bookmark_note_path` returns nil for nil input                                                                          | `nil` input → `nil`. Function does not crash on absent line.                                                                                                                            |
| `parsers.extract_bookmark_note_path` returns nil for empty string input                                                                 | `""` input → `nil`. Empty cells loop yields no return; fallback regex matches nothing.                                                                                                   |
| `parsers.extract_bookmark_note_path` returns an unquoted .md cell verbatim                                                              | `"notes/foo.md"` → `"notes/foo.md"`. Single-cell case; `.md` second-branch return.                                                                                                       |
| `parsers.extract_bookmark_note_path` strips surrounding double quotes from a quoted .md cell                                            | `'"notes/foo.md"'` → `"notes/foo.md"`. Outer `gsub` removes the quotes.                                                                                                                  |
| `parsers.extract_bookmark_note_path` strips surrounding single quotes from a quoted .md cell                                             | `"'notes/foo.md'"` → `"notes/foo.md"`. Same `gsub` covers both quote shapes.                                                                                                              |
| `parsers.extract_bookmark_note_path` skips http:// cells and returns the next .md cell                                                  | `"http://example.com\tnotes/foo.md"` → `"notes/foo.md"`. The http cell is skipped via `cell:match("^https?:")`.                                                                          |
| `parsers.extract_bookmark_note_path` skips https:// cells and returns the next .md cell                                                 | `"https://example.com\tnotes/foo.md"` → `"notes/foo.md"`. Same skip pattern.                                                                                                              |
| `parsers.extract_bookmark_note_path` returns the first .md cell when title cell precedes path cell                                      | `'"My Bookmark"\tnotes/topic.md'` → `"notes/topic.md"`. Title cell does not end in `.md` and resolver-stub returns nil → falls through to next cell.                                     |
| `parsers.extract_bookmark_note_path` skips empty and whitespace-only cells                                                              | `"\t   \tnotes/foo.md"` → `"notes/foo.md"`. Empty cells fail the `cell ~= ""` guard.                                                                                                      |
| `parsers.extract_bookmark_note_path` returns a non-.md cell when the resolver reports it as a real note                                  | Resolver stub returns truthy for `"notes/no-extension"`. Input `"notes/no-extension"` → `"notes/no-extension"`. Exercises the first-branch return (the disk-resolution path).            |
| `parsers.extract_bookmark_note_path` falls through when resolver returns nil and cell does not end in .md                                | Resolver stub returns nil. Input `"notes/no-extension\tnotes/foo.md"` → `"notes/foo.md"`. First cell rejected by both branches; second cell wins.                                       |
| `parsers.extract_bookmark_note_path` extracts a .md path via the line-level fallback regex                                              | Input is a single cell with a `.md` substring buried in noise (e.g. `"see notes/inline.md please"`) — the per-cell loop returns the cell verbatim because it ends in `.md` after... wait — needs a case where the cell does NOT match `%.md$` but the line-level fallback matches. Use a single-cell whose first non-whitespace token contains `.md` mid-cell with trailing chars (e.g. `"see notes/inline.md here"`). |
| `parsers.extract_bookmark_note_path` returns nil when neither cells nor fallback regex match                                            | Input `"plain text with no path"` → `nil`. No cell qualifies; fallback regex returns nil; function returns nil.                                                                          |
| `parsers.extract_bookmark_note_path` parses a mixed-shape fixture line by line                                                          | `fixtures/bookmarks_verbose.txt` loaded, split by `\n`, parsed per line. Expected paths asserted in input order. Empty lines yield `nil` (filtered out of the assertion list).            |

(Note: the fallback-regex case as worded above had inline reasoning; the
final spec will use a clean single-line input that bypasses both per-cell
branches but matches the line-level regex — for example, a TSV cell of
`"see notes/inline.md here"` whose trim+strip leaves it not ending in `.md`
and whose resolver returns nil, falling into the `line:match` fallback.)

A deliberate-failure / mutation verification is **not required** by this
slice — #15 already closed the "at least one parser has a mutation test"
parent criterion. Optional during implementation.

## Affected artifacts

- Modified: `lua/utils/obsidian_cli/parsers.lua` — adds resolver seam
  (~10 lines), changes one call site at line 274. Production code change
  scoped per the flag's Option B mandate.
- Modified: `tests/utils/obsidian_cli/parsers_spec.lua` — extended with
  ~14 new `extract_bookmark_note_path` cases, plus the `pre_case`/`post_case`
  scaffolding that installs and resets the resolver stub.
- New: `tests/utils/obsidian_cli/fixtures/bookmarks_verbose.txt` —
  hand-curated TSV sample, read line-by-line.
- Unchanged (verified by `git diff`): `lua/utils/obsidian_cli/init.lua`,
  `lua/utils/obsidian_cli/command.lua`, `lua/utils/obsidian_cli/shell.lua`,
  `lua/utils/obsidian_cli/presenter.lua`, `lua/config/commands.lua`,
  `lua/config/vaults.lua`, `tests/utils/obsidian_cli/init_spec.lua`,
  `tests/utils/obsidian_cli/command_spec.lua`,
  `tests/utils/obsidian_cli/fixtures/{search_context,paths,tasks_verbose,unresolved_verbose,backlinks_json}.txt`,
  `tests/init.lua`, `tests/run`, `tests/utils/wordcount_spec.lua`.
- Unchanged: closed sibling sub-issue folders (#14–#19) — this slice does
  not edit them.
- **Updated at closure:** parent `issue.md` parser progress line — flips to
  "6 of 6" with `extract_bookmark_note_path` added; the parser-coverage
  acceptance criterion checkbox flips to checked. The bookmark-parser flag
  is closed (struck through or removed per closer's call). Per `sdp-close`
  outward pass.
- New (closing artifact): `20-bookmark-parser-resolver-seam/aar.md` —
  records the strategy chosen, the constraint-qualification note (two
  setter-based seams, not one), the parser-coverage advance (5 of 6 → 6 of 6),
  the bookmark-parser flag closure, and any deviations from this plan.

## Dependencies

- **Sub-issue #14 (closed).** Provides the layered module shape, the
  `shell.set_runner` / `shell.reset_runner` pattern this slice mirrors,
  the `parsers.lua` module under change, and the bookmark-parser flag this
  slice resolves. See `14-layer-skeleton-tracer/aar.md` lines 47–52 for
  the flag's origin.
- **Sub-issues #15 / #16 / #17 / #18 / #19 (all closed).** Established the
  spec file conventions, the `pre_case`/`post_case` posture for resettable
  state, and the captured-fixture-by-hand pattern for representative inputs.
  This slice mirrors them end-to-end.
- **ADR-0001** — `mini.test` runner. Accepted.
- **ADR-0002** — folder slug `20-...` tracks GitHub issue number. Confirm
  `#20` at activation; rename folder if the actual issue gets a different
  number.
- No dependency on any other parent or any other cycle.

## Out of scope (deferred)

- **Consolidating the duplicated `vault_relpath_to_abs` between `init.lua`
  and `parsers.lua`.** Both modules carry a near-identical local copy.
  Pulling the shared helper into a fifth sibling module (e.g.
  `vault.lua`) would reduce duplication and make the resolver seam
  reusable for `init.lua`'s bookmark-keymap callsite. Recorded as a
  deepening candidate for a future cycle (or for the cycle's final
  sub-issue's deepening pass if it lands within scope).
- **Replacing `init.lua`'s `vault_relpath_to_abs` with a parsers-module
  call.** Same reasoning — out of scope here; would require touching
  `init.lua` and re-evaluating the `M.*` signature constraint's intent.
- **Integration / shell-seam coverage of `M.bookmarks_list_verbose` in
  `init.lua`.** That leaf opens a scratch buffer, sets a keymap, and
  calls `vault_relpath_to_abs` on the chosen line. Coverage requires the
  shell-seam plus child-Neovim assertions on buffer contents and keymap
  callbacks — same posture as the deferred backlinks integration tests.
  Deferred to a future presenter / shell-seam slice. **Note:** this is
  *not* the bookmark-parser flag; the bookmark-parser flag is fully
  closed by this slice. The integration coverage is its own future
  scope.
- **Command-builder tests for `command.bookmarks_verbose` and
  `command.bookmark_add`.** The parent's command-builder shell-escape
  criterion is already closed by #15 (and reinforced by #19). Per-leaf
  builder specs for the remaining builders (`history_list`, `history_read`,
  `diff`, `outline`, `wordcount`, `bookmarks_verbose`, `bookmark_add`,
  `task_toggle`) are nice-to-have, not required.
- **Any ADR-0003 work.** Reserved for the cycle's final sub-issue. The
  resolver seam introduced here is one more data point for the
  four-layer-pattern durability assessment — record it in the AAR for
  the ADR-0003 sub-issue to consult.
- **Property-based or generative testing of the cell-picker matrix.**
  Hand-curated cases per branch are sufficient and consistent with
  preceding parser-pass slices.

## Pre-activation review (parent linkage)

### Parent acceptance criteria this slice closes outright

- **"Every output parser introduced or extracted by the deepening has at
  least one passing unit test under `tests/utils/obsidian_cli/`,
  exercised by `./tests/run`."** Flips from "5 of 6" to "6 of 6" after
  this slice closes. **The criterion's checkbox flips to checked.**
  This is the slice's load-bearing parent-criterion impact.

### Parent acceptance criteria this slice partially advances

None. The parser-coverage criterion is closed outright; no other open
parent criterion is materially advanced.

### Parent acceptance criteria this slice maintains (does not regress)

- `./tests/run` exits 0 on the whole suite.
- `PATH=...` test suite green with `obsidian` absent.
- `git diff` against `lua/config/commands.lua` empty.
- No reaching into local functions or monkey-patching internals (the
  resolver seam is a public test surface, not internals access).
- 14 `M.*` exports on `init.lua` unchanged.
- Single shell-call grep (constraint #3 in the parent) — the resolver
  seam does not introduce a new `systemlist`/`os.execute`/`io.popen` call.

### Parent flags this slice resolves or updates

- **Bookmark-parser flag (`#14 AAR → bookmark-parser sub-issue`):**
  **fully resolved.** Pre-document requirement satisfied (Option B
  selected and justified above). Production-code change (resolver seam)
  landed as fix-with-test per the flag's wording. Tests cover the
  observable behaviors of `extract_bookmark_note_path` including the
  disk-resolution branch (via the stubbed resolver). The flag is
  removed (or struck through) at closure.
- **Backlinks-parser flag (`#14 AAR → backlinks-parser sub-issue`):**
  unchanged. Pure-parser sub-requirement closed by #19; integration-path
  sub-requirement remains open and is not in scope here.

### Constraint qualification (recorded in the AAR)

Parent constraint #3 (implementation-approach narrative): "the
shell-adapter setter is the seam; everything else uses pure-module
require." After this slice, **two** test seams exist:

- `shell.set_runner(fn)` / `shell.reset_runner()` — wraps `vim.fn.systemlist`.
- `parsers.set_resolver(fn)` / `parsers.reset_resolver()` — wraps
  `vault_relpath_to_abs` (which calls `vim.loop.fs_stat`/`fs_realpath`).

Both seams are setter-based, both default to the real implementation,
both live on the layered module that owns the impure dependency, and
neither is monkey-patched into existence by tests. The constraint's
spirit (no global monkey-patching, no private-function reach-in) holds;
its letter ("the seam") is amended to "the seams." The AAR records this
explicitly.

### Outward pass — parent issue updates after closure

On closure, update parent `issue.md`:

1. Parser progress line (lines 29–32) to "Progress as of #20: 6 of 6" and
   add `extract_bookmark_note_path` [#20] to the covered list. **Flip the
   parser-coverage acceptance criterion checkbox to `[x]`.**
2. Bookmark-parser flag entry (lines 172–185): mark as resolved by #20
   (struck through, or removed entirely with a closing pointer to
   `20-...aar.md`). The exact form is the closer's call (per `sdp-close`).

This slice's AAR also records:

- Parser-coverage advance: `5/6 → 6/6` (parent criterion fully closed).
- Bookmark-parser flag transition: open → closed.
- Constraint #3 qualification: one seam → two seams, with rationale.
- Production code change: resolver seam on `parsers.lua` (~10 lines).
  Fix-with-test scope per the flag's mandate.
- Any deviations from the proposed test list, with rationale.
- Any defects-fixed-with-test in `extract_bookmark_note_path` (none
  expected; the function's behavior is preserved).
- Any new flag if the implementation surfaces an unresolvable nuance.
  Likely candidates worth recording (only if observed): the duplicated
  `vault_relpath_to_abs` between `init.lua` and `parsers.lua` (a clear
  deepening candidate); behavior mismatches between the bookmark-parser
  fallback regex and what real `obsidian bookmarks verbose` emits
  (would suggest a fixture revision); cells whose outer-quote strip
  produces an empty result (currently silently dropped — worth a fixture
  line if observed in real output).

No new flags expected — `extract_bookmark_note_path` is well-bounded by
its documented contract once the resolver seam is in place.

## Suggested GitHub issue title

`feature: parser-pass slice — extract_bookmark_note_path + parsers.set_resolver seam`

Alternative shorter forms:

- `feature: extract_bookmark_note_path specs + resolver DI seam on parsers.lua`
- `test: bookmark-parser cell-picker (TSV) + parsers.set_resolver seam`
