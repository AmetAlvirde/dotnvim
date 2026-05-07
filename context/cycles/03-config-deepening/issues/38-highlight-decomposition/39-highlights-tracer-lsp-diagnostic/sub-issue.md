# Sub-issue #39 — Highlights tracer + `lsp_diagnostic` first contact

GitHub issue: #39. First sub-issue under parent #38 (Candidate C —
`solarized.lua` highlight decomposition) of cycle
`03-config-deepening`.

## Description

Tracer slice for parent #38. Establish the smallest end-to-end path
that exercises the section-module / composition-root shape against
one real section.

Build `lua/colors/highlights/` as a directory of pure-function
section modules. Extract one well-bounded section
(`lsp_diagnostic`, see below) into
`lua/colors/highlights/lsp_diagnostic.lua` exposing
`M.highlights(c) → table`. Reshape `solarized.setup()` into a
composition root: declare a `SECTIONS` list, require each module,
merge the returned tables into a single `merged` table, and apply
via one `vim.api.nvim_set_hl` loop. The remaining ~330 highlight
entries currently inlined inside `setup()` stay as a single
intermediate-state table, fed into the same merge step as the
extracted section's output. The trailing manual
`vim.api.nvim_set_hl` block at lines ~462–491 stays imperative in
this sub-issue — folding it into section modules is deferred to
the markdown / template-literals batch.

Add the first per-section spec at
`tests/colors/highlights/lsp_diagnostic_spec.lua` exercising
`M.highlights(c)` as a pure function. Add the first composition
spec at `tests/colors/solarized_composition_spec.lua` exercising
`solarized.setup()` end-to-end via a `vim.api.nvim_set_hl` fake.

This sub-issue resolves two of the parent's four
"resolved-through-implementation" items:

- **Section partition starting decision** — propose
  `lsp_diagnostic` as the tracer extraction; record the resulting
  partition starting point in this sub-issue's AAR.
- **Merge order / override semantics** — propose **last-module-wins**
  (the SECTIONS list is order-significant; later modules overwrite
  earlier modules' keys). Record the rationale and the
  override-pair handling plan in the AAR.

The remaining two parent decisions — composition-test depth (open
question #5) and the ADR-0004 carry-forward note — are deferred
to the closing sub-issue per the parent's sequencing.

This mirrors parent #22's tracer (`#23` migrated `ObsCLITasks`
alone) and parent #32's tracer (`#33` migrated lualine alone with
the polling timer retired): one section extracted, the
composition shape proven, the rest of the inlined table left for
subsequent batches.

## Dependency classification

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `vim.api.nvim_set_hl` (called by `solarized.setup()`'s apply loop and the trailing manual block) | True external (Neovim API) | Per-test swap in `pre_case`: replace with a recording fake that captures `(group, opts)` into a per-test table; restore in `post_case`. Same pattern parent #22 used for `vim.api.nvim_create_user_command` and parent #32 used for `vim.api.nvim_set_hl` itself. |
| `vim.cmd` / `vim.defer_fn` (called downstream of `setup()` in `set_theme`/`toggle`, and by the still-present `LualineRefresh` defer blocks) | True external | Per-test no-op fakes via `pre_case`; restore via `post_case`. The composition spec calls `setup()` directly to avoid `set_theme`'s `vim.cmd("redraw!")` side-effect, but the fakes are kept as a safety net per the cycle pattern. |
| `vim.fn.has` / `io.popen` (inside `os_theme.detect()`) | True external | Stub `vim.fn.has` to return 0 in tests so the shell-out branch is skipped; `setup("dark")` / `setup("light")` is called with an explicit theme override, so `os_theme.detect()` is bypassed regardless. The stub is defense-in-depth. |
| `colors.solarized` module | In-process | Test directly through `M.setup(theme_override)`. The composition spec records the apply-loop output. |
| `colors.highlights.lsp_diagnostic` module | In-process | Test directly through `M.highlights(c)` — pure function, no fakes needed. |
| `colors.os_theme` | In-process; not exercised in this spec | `setup()` is called with an explicit `theme_override` argument so `os_theme.detect()` never runs. |

No new ports introduced. Section modules are pure Lua functions
with a palette table as their single argument; no remote
dependency, no I/O, no event bus.

## Interface design

Three design alternatives compared. Final choice resolved in this
sub-issue's AAR per the parent issue's "resolved through
implementation" notes.

### Alternative A — minimal surface: SECTIONS list + inline `compose`

```lua
-- in lua/colors/solarized.lua

local SECTIONS = {
  "colors.highlights.lsp_diagnostic",
  -- subsequent sub-issues append here
}

function M.setup(theme_override)
  local theme = theme_override or os_theme.detect()
  local c = theme == "dark" and dark_colors or light_colors
  vim.o.background = theme

  local merged = {}
  for _, mod in ipairs(SECTIONS) do
    for group, opts in pairs(require(mod).highlights(c)) do
      merged[group] = opts
    end
  end

  -- intermediate inlined table (shrinks each sub-issue):
  local rest = {
    Normal = { fg = c.fg0, bg = c.bg0 },
    -- ... ~330 remaining entries ...
    markdownCalloutTitle = { fg = c.blue, bold = true },
  }
  for group, opts in pairs(rest) do
    merged[group] = opts
  end

  for group, opts in pairs(merged) do
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- trailing manual block: STILL HERE this sub-issue.
  -- Folded into section modules in the markdown / template-literals batch.
  vim.api.nvim_set_hl(0, "javaScriptStringT", { fg = c.cyan, bg = c.bg1 })
  -- ... ~17 more manual nvim_set_hl calls ...

  vim.g.colors_name = "solarized"
  emit()
end
```

**Pros:** Lowest indirection. `compose` logic is two short loops
inline — no helper function, no extra module. Mirrors parent
#22's "registrar lives where its consumer lives" resolution and
parent #32's "registry stays module-local" resolution. The
SECTIONS list is the declarative spine; appending a section is
one line.

**Cons:** When all sections are extracted, the inline `compose`
loop becomes load-bearing in the closing sub-issue's
"single apply loop" AC — we read it twice (extract + compose +
apply). Acceptable: the loops are five lines each.

### Alternative B — extracted `compose(c)` helper

```lua
-- in lua/colors/solarized.lua

local SECTIONS = { "colors.highlights.lsp_diagnostic" }

local function compose(c, inline)
  local merged = {}
  for _, mod in ipairs(SECTIONS) do
    for group, opts in pairs(require(mod).highlights(c)) do
      merged[group] = opts
    end
  end
  if inline then
    for group, opts in pairs(inline) do merged[group] = opts end
  end
  return merged
end

function M.setup(theme_override)
  local theme = theme_override or os_theme.detect()
  local c = theme == "dark" and dark_colors or light_colors
  vim.o.background = theme

  local rest = { ... }  -- shrinks each sub-issue
  for group, opts in pairs(compose(c, rest)) do
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- trailing manual block: still here this sub-issue.
  -- ...

  vim.g.colors_name = "solarized"
  emit()
end
```

**Pros:** `compose` is a named function with a typed signature;
arguably easier to name in a future spec.

**Cons:** The `inline` parameter is scaffolding that exists only
for the duration of the cycle — by the closing sub-issue it
goes away (everything is in SECTIONS), and the helper signature
either changes or carries a vestigial argument. A function whose
signature is provisional is worse than two inline loops. Also
introduces a require cycle risk if `compose` ever moved to its
own module.

### Alternative C — sibling module `lua/colors/highlights/init.lua` orchestrator

```lua
-- in lua/colors/highlights/init.lua
local M = {}
local SECTIONS = { "colors.highlights.lsp_diagnostic" }
function M.compose(c) ... end
return M

-- in lua/colors/solarized.lua
local highlights = require("colors.highlights")
for group, opts in pairs(highlights.compose(c)) do
  vim.api.nvim_set_hl(0, group, opts)
end
```

**Pros:** The orchestrator is unambiguously a separate module;
section-module discovery could be made dynamic later
(e.g., `vim.fn.glob("colors/highlights/*.lua")`).

**Cons:** Premature generalization. The cycle PRD's
non-goal #2 is exactly "generalizing the section-module pattern";
hoisting the SECTIONS list into its own module structurally
invites that generalization. The orchestrator buys nothing for
solarized's single composition root and one consumer.

### Override-pair handling (orthogonal to A/B/C)

The current `setup()` has an imperative trailing block that
overwrites earlier entries (`javaScriptStringT`,
`markdownCodeBlock`, `markdownInlineCode`). After the closing
sub-issue, those overrides land via section-module ordering
(template-literals after the section that originally held the
group, last-module-wins).

In **this** sub-issue, `lsp_diagnostic` has no override pair —
none of its entries are overwritten by the trailing manual
block. The merge order decision is therefore observable only
through the inlined intermediate table vs. the `lsp_diagnostic`
module: if both defined the same group, last-module-wins. They
don't, so this sub-issue does not exercise the override-pair
path. The decision is recorded in the AAR for the markdown /
template-literals batch to inherit.

### Chosen (proposed; final in AAR)

**Alternative A.** Inline `compose` loops; `SECTIONS` list
hosted as a top-level local in `solarized.lua`.

**Reason for A:** Single composition root, one consumer, lowest
indirection. The inline loops are short and read top-to-bottom
in the file — supports user story 6 ("read top-to-bottom as a
declarative spine"). Mirrors parent #22 (registrar-with-consumer)
and parent #32 (subscribe-with-emitter).

**Rejected B:** the `inline` parameter is provisional scaffolding;
a helper with a vestigial argument is worse than two short inline
loops.

**Rejected C:** premature generalization per cycle PRD non-goal #2.

**Section choice — `lsp_diagnostic` (proposed; final in AAR):**

- 9 entries, smallest well-bounded section in the inlined table.
- No `vim.*` references in the entries — pure palette consumption.
- No override pairs — the trailing manual block doesn't touch
  any LSP / Diagnostic group. Tracer can prove the section-module
  shape without also resolving override semantics.
- Visual concern is unambiguous: LSP reference highlighting and
  diagnostic severity colors. Not entangled with syntax / treesitter.

Alternative section: `base` — foundational and read-first by a
maintainer skimming `setup()`. Rejected for the tracer because
its ~30 entries make the per-section spec heavier without
proving anything new about the shape; bigger sections come
later in the batches.

### Public interface (post-sub-issue)

```lua
-- colors.solarized — unchanged public surface
M.setup(theme_override)              -- unchanged signature; reshape internal
M.set_theme(theme)                   -- unchanged
M.toggle()                           -- unchanged
M.subscribe(fn) -> unsubscribe_fn    -- unchanged (from #33)
M.colors / M.dark_colors / M.light_colors  -- unchanged
```

```lua
-- colors.highlights.lsp_diagnostic — new module, public
local M = {}

function M.highlights(c)
  return {
    LspReferenceText  = { bg = c.bg2 },
    LspReferenceRead  = { bg = c.bg2 },
    LspReferenceWrite = { bg = c.bg2 },
    DiagnosticError   = { fg = c.red },
    DiagnosticWarn    = { fg = c.yellow },
    DiagnosticInfo    = { fg = c.blue },
    DiagnosticHint    = { fg = c.cyan },
  }
end

return M
```

Pure: takes `c` (a palette table), returns a highlight-group map.
No `vim.*` calls, no `require` cycles, no closure over outer
state. Independently `require`-able and unit-testable.

## Acceptance criteria

- [ ] `lua/colors/highlights/lsp_diagnostic.lua` exists, returns
      a module with `M.highlights(c) → table`, and contains zero
      `vim.*` references. Verified by
      `grep -n 'vim\.' lua/colors/highlights/lsp_diagnostic.lua`
      returning zero matches.
- [ ] The section module returns a table with exactly the seven
      groups listed in the parent issue's
      `lsp_diagnostic` row: `LspReferenceText`,
      `LspReferenceRead`, `LspReferenceWrite`, `DiagnosticError`,
      `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`. Each
      entry's attribute table is byte-identical to the
      pre-sub-issue inline definition.
- [ ] `lua/colors/solarized.lua`'s `setup()` body declares a
      `SECTIONS` table-local containing the string
      `"colors.highlights.lsp_diagnostic"` (and only that, this
      sub-issue). The seven `lsp_diagnostic` entries are removed
      from the inlined `highlights` table. Verified by reading
      the post-sub-issue `setup()` body against
      `git show HEAD~:lua/colors/solarized.lua`.
- [ ] `setup()` ends with a single
      `for group, opts in pairs(merged) do
      vim.api.nvim_set_hl(0, group, opts) end` apply loop. The
      trailing manual `vim.api.nvim_set_hl` block at lines
      ~462–491 is **explicitly preserved unchanged** in this
      sub-issue. (It folds into section modules in the markdown
      / template-literals batch, not here.)
- [ ] The palette tables (`colors`, `dark_colors`,
      `light_colors`) and the public surface (`M.setup`,
      `M.set_theme`, `M.toggle`, `M.subscribe`, `M.colors`,
      `M.dark_colors`, `M.light_colors`) are unchanged. The
      `subscribers` table, `subscribe`/`emit` registry,
      `os_theme.detect()` call site, `vim.o.background = theme`
      assignment, `vim.g.colors_name = "solarized"` write,
      `emit()` call, and `set_theme`/`toggle`'s
      `vim.g.colors_name = nil` clear are preserved.
- [ ] `tests/colors/highlights/lsp_diagnostic_spec.lua` exists
      and exercises `M.highlights(c)` as a pure function:
      passes a representative palette, asserts the returned
      table contains all seven groups with the expected
      attributes for at least two entries (one
      `LspReference*` and one `Diagnostic*`).
- [ ] `tests/colors/solarized_composition_spec.lua` exists and
      exercises `solarized.setup("dark")` end-to-end: stubs
      `vim.api.nvim_set_hl` to record `(group, opts)` calls,
      calls `setup("dark")`, asserts the recorded calls include
      every entry from the `lsp_diagnostic` section module and
      at least one entry from the inlined intermediate table
      (e.g., `Normal`, `Comment`). Repeats the assertion for
      `setup("light")` to cover both palettes.
- [ ] No edits to `lua/colors/os_theme.lua`,
      `lua/config/autocmds.lua`, `lua/plugins/lualine.lua`,
      `lua/config/commands.lua`,
      `lua/config/commands_registrar.lua`,
      `lua/utils/obsidian_cli/`, `lua/utils/wordcount.lua`, or
      `lua/utils/macos_codesign/`. Verified by `git diff`
      against the cycle base showing changes only under
      `lua/colors/solarized.lua`,
      `lua/colors/highlights/lsp_diagnostic.lua`,
      `tests/colors/highlights/lsp_diagnostic_spec.lua`, and
      `tests/colors/solarized_composition_spec.lua`.
- [ ] `./tests/run` exits 0 on the whole suite — including
      cycle 01, cycle 02, and cycle 03 (parents #22, #30, #32)
      specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 equivalent —
      the new specs do not depend on any external binary; the
      composition spec stubs `vim.fn.has` to 0 (defense-in-depth)
      and calls `setup` with an explicit `theme_override`.
- [ ] No reaching into module locals or monkey-patching
      internals beyond the sanctioned per-test
      `vim.api.nvim_set_hl` / `vim.cmd` / `vim.defer_fn` /
      `vim.fn.has` swaps. The composition spec calls
      `solarized.setup` only through its public name; the
      per-section spec calls `lsp_diagnostic.highlights` only
      through its public name.
- [ ] **Resolved-through-implementation decisions recorded in
      AAR:** section-partition starting point → which sections
      stay candidates and in what order; merge-order / override
      semantics → **last-module-wins** confirmed (or
      **no-shared-keys** if the design pass surfaces a reason
      to flip).

## Proposed tests

Two new spec files.

### `tests/colors/highlights/lsp_diagnostic_spec.lua` — per-section, pure

No `pre_case` / `post_case` swaps required: the section module
is a pure function with no `vim.*` dependencies.

Test cases:

1. `lsp_diagnostic.highlights returns the seven expected groups`
   — pass a representative palette table
   (`{ bg2 = "#aaa", red = "#f00", yellow = "#ff0", blue = "#00f",
   cyan = "#0ff" }`), assert the returned table has exactly the
   seven keys.
2. `lsp_diagnostic.highlights propagates palette colors into
   Diagnostic groups` — pass the palette, assert
   `result.DiagnosticError.fg == c.red`,
   `result.DiagnosticWarn.fg == c.yellow`, etc.
3. `lsp_diagnostic.highlights propagates bg2 into LspReference
   groups` — assert `result.LspReferenceText.bg == c.bg2` and the
   same for `Read`/`Write`.
4. `lsp_diagnostic.highlights is pure` — call twice with the
   same palette, assert the two return values are
   structurally equal but not the same table identity (each
   call constructs a fresh table).

### `tests/colors/solarized_composition_spec.lua` — end-to-end, faked apply

`pre_case` swaps:

- `vim.api.nvim_set_hl` → recording fake that captures
  `(group, opts)` into `_G.recorded_hls = {}`.
- `vim.cmd` → no-op fake.
- `vim.defer_fn` → invokes callback synchronously.
- `vim.fn.has` → returns 0 (defense-in-depth; not exercised
  because the spec calls `setup(theme_override)`).
- `vim.o.background` → pinned to `"dark"` per the
  carry-forward note from #33's AAR (prevents the
  colorscheme-reapply path from firing during the test).

`post_case`: restore originals; clear
`package.loaded["colors.solarized"]`,
`package.loaded["colors.highlights.lsp_diagnostic"]`,
`package.loaded["colors.os_theme"]`.

Test cases:

1. `setup('dark') applies all seven lsp_diagnostic groups` —
   call `solarized.setup("dark")`, assert the recorded
   `(group, opts)` set includes
   `LspReferenceText`, `DiagnosticError`, etc., with
   `dark_colors`-derived attributes
   (e.g., `recorded.DiagnosticError.fg == "#f23749"` —
   `colors.red`).
2. `setup('light') applies all seven lsp_diagnostic groups` —
   re-runs the assertion against `light_colors`-derived
   attributes (palette accent colors are identical between
   `dark_colors` and `light_colors`, so the LSP/Diagnostic
   palette values are the same; the `bg2` value differs
   between palettes, exercised via `LspReferenceText.bg`).
3. `setup('dark') applies a representative inlined entry` —
   assert the recorded set includes `Normal` and `Comment`
   (still in the inlined intermediate table this sub-issue),
   with the expected dark-palette attributes. This is the
   tracer probe that the inlined-rest path still works.
4. `setup('dark') still applies the trailing manual block` —
   assert the recorded set includes `javaScriptStringT` with
   `{ fg = "#259d94", bg = "#093946" }`
   (`{ fg = c.cyan, bg = c.bg1 }` against `dark_colors`). The
   trailing block's overwrite of an earlier entry — current
   behavior — is preserved.

The composition spec is the closure signal per cycle PRD
constraint #6 in tracer form. Subsequent sub-issues extend it
as more sections move out of the inlined table; the closing
sub-issue resolves whether to promote it from a representative
subset to a full-table snapshot (parent open question #5).

## Affected artifacts

- **`lua/colors/highlights/lsp_diagnostic.lua`** — new file.
  ~12 lines: `local M = {}`, `function M.highlights(c)`, return
  table of seven groups, `return M`.
- **`lua/colors/solarized.lua`** —
  - Add a `SECTIONS` table-local before `M.setup` (or inside
    `setup()`'s body — design pass picks one; default: top-level
    so it's visible without scrolling into `setup`).
  - Reshape `setup()`'s body: build `merged` from `SECTIONS` +
    intermediate `rest` table, replace the existing single apply
    loop's source from `highlights` to `merged`.
  - Remove the seven `lsp_diagnostic` entries from the inlined
    table (lines ~224–232, mapped to the equivalent post-#36
    line numbers).
  - The trailing manual `vim.api.nvim_set_hl` block (lines
    ~462–491) is **not modified** in this sub-issue.
- **`tests/colors/highlights/lsp_diagnostic_spec.lua`** — new
  file. The `tests/colors/highlights/` directory does not yet
  exist and is created in this sub-issue.
- **`tests/colors/solarized_composition_spec.lua`** — new file.

No edits anywhere else.

## Dependencies

- **Cycle 03 parent #22 (A) closure** — established the
  fake-the-API per-case swap pattern that the composition spec
  reuses for `vim.api.nvim_set_hl`. Closed.
- **Cycle 03 parent #30 (D) closure** — proved the discipline of
  not reaching into module locals beyond sanctioned setter
  seams. Section modules are tested through their public
  `M.highlights(c)` surface. Closed.
- **Cycle 03 parent #32 (B) closure** — established the
  post-`setup()` shape this sub-issue inherits unchanged:
  `subscribe`/`emit` registry, `os_theme.detect()` call site,
  `vim.g.colors_name` clear in `set_theme`/`toggle`. The
  carry-forward note about pinning `vim.o.background` in
  `pre_case` to suppress the colorscheme-reapply path is
  applied to the new composition spec. Closed.
- **Sub-issue #33's spec pattern** — the composition spec
  reuses the per-case `vim.api.nvim_set_hl` / `vim.cmd` /
  `vim.defer_fn` / `vim.fn.has` swap pattern and the
  `package.loaded[...] = nil` reload trick verbatim.
- **No dependency on later sub-issues under parent #38.** This
  sub-issue is the tracer; #40+ build on its proof.
- **No dependency on later parents.** Parent #38 is the last
  parent in cycle 03's resolved sequencing.
