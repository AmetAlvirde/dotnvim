# Sub-issue #40 — Code-syntax batch (`base` + `syntax` + `treesitter`)

GitHub issue: #40. Second sub-issue under parent #38 (Candidate C —
`solarized.lua` highlight decomposition) of cycle
`03-config-deepening`.

## Description

First post-tracer extraction batch for parent #38. Extract the
three remaining non-markdown sections from the inlined
intermediate `rest` table into pure-function section modules:

- `lua/colors/highlights/base.lua` — Normal/NormalFloat/NormalNC,
  Cursor/CursorLine/CursorColumn/CursorLineNr, line numbers,
  StatusLine, TabLine, Windows (WinSeparator/VertSplit), Search,
  Visual, Diff, Folding, SignColumn, ColorColumn, Pmenu, Messages.
- `lua/colors/highlights/syntax.lua` — vim-default syntax groups:
  Comment, Constant/String/Character/Number/Boolean/Float,
  Identifier/Function, Statement/Conditional/Repeat/Label/
  Operator/Keyword/Exception, PreProc/Include/Define/Macro/
  PreCondit, Type/StorageClass/Structure/Typedef,
  Special/SpecialChar/Tag/Delimiter/SpecialComment/Debug,
  Underlined, Bold, Italic.
- `lua/colors/highlights/treesitter.lua` — non-markdown
  `@`-prefixed groups: `@comment`, `@string`/`@number`/`@boolean`,
  `@function*`/`@parameter*`/`@method`/`@field`/`@property`/
  `@constructor`, `@conditional`/`@repeat`/`@label`/`@keyword*`/
  `@operator`/`@exception`, `@type*`/`@storageclass`/`@attribute`,
  `@variable*`/`@constant*`/`@namespace`/`@symbol`,
  `@text*` cluster, `@tag*`, `@punctuation*`,
  `RainbowDelimiter*`, `@macro`/`@define`/`@include`/`@preproc`.

Each section module follows the shape proven in #39: pure
function `M.highlights(c) → table`, no `vim.*` references, no
closure over outer state. The three modules are appended to
`SECTIONS` (in order: `base`, `syntax`, `treesitter`) and their
entries are removed from the inlined `rest` table. The trailing
manual `vim.api.nvim_set_hl` block at the end of `setup()`
remains untouched in this sub-issue — the markdown batch (#41)
folds it into section modules alongside the markdown / template-
literals / obsidian extractions.

After #40, the inlined `rest` table holds only the markdown-flavor
sections and the HTML/template-literal block:
`javaScriptStringT` + `htmlTag*` (~11 entries),
`markdown*` legacy groups (~50 entries), `@markdown.*` groups
(~50 entries), Obsidian extensions (~10 entries) — roughly 120
entries total. Everything else has moved to `lua/colors/highlights/`.

This is a pure mechanical extraction batch: copy entries from
`rest` into a new section module verbatim, append the module
path to `SECTIONS`, delete the entries from `rest`, add a
per-section spec, extend the composition spec to assert one
representative entry from each new section. No override-pair
handling, no public-surface change, no test-pattern change. The
batch mirrors parent #22's mid-cycle migration sub-issues
(#24/#25/#26/#27 — pure registrar migrations, one row at a time
or in small groups).

The parent issue's "Subsequent sub-issues" plan listed the
code-syntax batch as `syntax` + `lsp_diagnostic` + `treesitter`
and did not assign `base` to a batch. #39 already extracted
`lsp_diagnostic` as the tracer; this sub-issue places `base` in
the code-syntax batch (the natural home — UI-chrome and code
highlighting are both non-markdown, and `base` has no override
pairs). The placement is recorded in this sub-issue's AAR and
reflected in the resulting `SECTIONS` ordering.

## Dependency classification

Identical to #39 — no new dependencies introduced.

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `vim.api.nvim_set_hl` (called by `setup()`'s apply loop and the still-present trailing manual block) | True external (Neovim API) | Per-test recording fake established by #39's composition spec; reuse verbatim. |
| `vim.cmd` / `vim.defer_fn` | True external | Per-test no-op fakes; reused. |
| `vim.fn.has` | True external | Stubbed to 0; defense-in-depth. |
| `colors.solarized` | In-process | Public `M.setup(theme_override)`. |
| `colors.highlights.base` / `syntax` / `treesitter` (new) | In-process | Public `M.highlights(c)`. Pure functions, no fakes needed. |
| `colors.highlights.lsp_diagnostic` (existing) | In-process | Already exercised by its own spec; the composition spec keeps asserting one of its entries to detect regressions. |
| `colors.os_theme` | In-process; not exercised | `setup` is called with explicit `theme_override`. |

No new ports introduced. Section modules remain pure Lua
functions consuming a palette table.

## Interface design

The shape was decided in #39: pure section modules, top-level
`SECTIONS` list, inline `compose` loops in `setup()`,
last-module-wins merge order. This sub-issue applies that shape
to three more sections — no new design call to make at the
composition-root level.

The remaining design decision is **section partition refinement**:
the parent issue listed eight candidate sections, the tracer
extracted one, and this sub-issue extracts three more. The
question this batch answers: do `base`, `syntax`, and
`treesitter` stay separate, or does the design pass surface a
reason to merge any pair?

### Alternative A — three separate modules (proposed)

Each of `base`, `syntax`, `treesitter` is its own file under
`lua/colors/highlights/`. Three section modules, three
per-section specs, three new lines in `SECTIONS`.

**Pros:** Each module maps cleanly to one visual concern — UI
chrome (`base`), vim-default syntax (`syntax`), treesitter
overrides (`treesitter`). Aligns with the parent's "section
modules serve `solarized.lua`" framing and supports user story
6 (top-to-bottom declarative spine — three section names read
as three concerns). Per-section specs stay focused; a future
maintainer tweaking a `@function` color edits one file and
runs one spec. Mirrors #39's per-section grain.

**Cons:** `treesitter` is the largest module in the batch (~70
entries). If a future cycle adds more `@`-prefixed groups, the
file grows; merging it with `syntax` would split the syntax
concern across two files but keep file size flat. Acceptable —
file size isn't a binding constraint.

### Alternative B — collapse `syntax` + `treesitter` into one `syntax` module

The vim-default syntax groups and the treesitter `@`-prefixed
groups cover the same visual concern (code coloring). Merging
them into one ~110-entry module reduces SECTIONS list depth and
puts all code-coloring overrides in one place.

**Pros:** Single source of truth for "how code is colored"
across vim's two syntax engines (legacy syntax and treesitter).
Fewer files, fewer specs.

**Cons:** Conflates two distinct domain concepts —
treesitter overrides exist precisely because `:hi` for a
vim-default group doesn't reach treesitter-captured ranges.
Naming becomes ambiguous: a file called `syntax.lua` that
contains `["@function"]` entries surprises a reader who
expects vim-default groups only. The two cluster also have
different update cadences (vim-default groups are stable;
treesitter group names evolve with the `nvim-treesitter` plugin's
capture renames). Merging them couples those cadences.

### Alternative C — collapse `base` + `syntax` into one `core` module

Treat all non-treesitter, non-markdown groups as "core" and
keep `treesitter` separate.

**Pros:** Two modules instead of three for the batch, smaller
SECTIONS list.

**Cons:** Same conflation problem in the other direction — UI
chrome (Normal, StatusLine) and syntax coloring (Comment,
Keyword) are different visual concerns. A maintainer editing
the statusline color does not want to read 30 lines of syntax
groups in the same file.

### Chosen (proposed; final in AAR)

**Alternative A.** Three separate modules: `base`, `syntax`,
`treesitter`.

**Reason for A:** Each module maps to one visual concern;
per-section specs stay focused; the parent's starting partition
(eight sections) is preserved with one resolved correction
(`base` placed in the code-syntax batch). The file sizes are
all under the rough cap implied by `lsp_diagnostic`'s 12-line
proof — `base` ~30 entries, `syntax` ~30 entries,
`treesitter` ~70 entries. None warrant a sub-split.

**Rejected B:** conflates two distinct domain concerns
(legacy syntax engine vs. treesitter capture overrides) with
different update cadences.

**Rejected C:** conflates UI chrome with code coloring; impedes
the maintainer-editing-one-concern flow that user story 3
describes.

### Public interface (post-sub-issue)

```lua
-- lua/colors/highlights/base.lua
local M = {}
function M.highlights(c)
  return {
    Normal       = { fg = c.fg0, bg = c.bg0 },
    NormalFloat  = { fg = c.fg0, bg = c.bg1 },
    -- ... ~30 UI-chrome entries ...
    Question     = { fg = c.cyan, bg = c.bg0 },
  }
end
return M
```

```lua
-- lua/colors/highlights/syntax.lua
local M = {}
function M.highlights(c)
  return {
    Comment   = { fg = c.fg2, italic = true },
    Constant  = { fg = c.cyan },
    -- ... ~30 vim-default syntax entries ...
    Italic    = { italic = true },
  }
end
return M
```

```lua
-- lua/colors/highlights/treesitter.lua
local M = {}
function M.highlights(c)
  return {
    ["@comment"]              = { fg = c.fg2, italic = true },
    ["@string"]               = { fg = c.cyan },
    -- ... ~70 @-prefixed entries plus rainbow delimiters
    --     plus @macro/@define/@include/@preproc cluster ...
    ["@preproc"]              = { fg = c.orange },
  }
end
return M
```

```lua
-- in lua/colors/solarized.lua
local SECTIONS = {
  "colors.highlights.lsp_diagnostic",
  "colors.highlights.base",
  "colors.highlights.syntax",
  "colors.highlights.treesitter",
}
```

`solarized.lua`'s public surface (`M.setup`, `M.set_theme`,
`M.toggle`, `M.subscribe`, `M.colors`, `M.dark_colors`,
`M.light_colors`) is unchanged. The `subscribers` registry,
`emit`, `os_theme.detect()` call site, `vim.o.background`
assignment, `vim.g.colors_name` write, `emit()` call, and the
trailing manual `nvim_set_hl` block are all preserved unchanged.

## Acceptance criteria

- [ ] `lua/colors/highlights/base.lua` exists, returns a module
      with `M.highlights(c) → table`, contains zero `vim.*`
      references. Verified by
      `grep -n 'vim\.' lua/colors/highlights/base.lua` returning
      zero matches.
- [ ] `lua/colors/highlights/syntax.lua` and
      `lua/colors/highlights/treesitter.lua` exist with the
      same shape and the same zero-`vim.*` invariant.
- [ ] The three new section modules' returned tables, taken
      together, contain every entry that was in the inlined
      `rest` table's "Basic colors" through "Messages" block,
      "Syntax highlighting" through `Italic`, and `["@comment"]`
      through `["@preproc"]` (including the rainbow-delimiter
      block). Each entry's attribute table is byte-identical to
      the pre-sub-issue inline definition.
- [ ] `lua/colors/solarized.lua`'s `SECTIONS` table-local
      contains exactly four entries in this order:
      `"colors.highlights.lsp_diagnostic"`,
      `"colors.highlights.base"`,
      `"colors.highlights.syntax"`,
      `"colors.highlights.treesitter"`. Order is documented as
      reflecting the last-module-wins merge convention even
      though no override pair is exercised by these four
      sections.
- [ ] The inlined `rest` table in `setup()` no longer contains
      the entries that moved into the three new modules.
      Verified by reading the post-sub-issue `setup()` body and
      confirming `rest` holds only HTML/template-literal block,
      `markdown*` legacy groups, `@markdown.*` groups, and the
      Obsidian extensions (≈120 entries).
- [ ] `setup()` still ends with a single
      `for group, opts in pairs(merged) do
      vim.api.nvim_set_hl(0, group, opts) end` apply loop. The
      trailing manual `vim.api.nvim_set_hl` block at lines
      ~462–491 is **explicitly preserved unchanged** in this
      sub-issue — folded into section modules in the markdown
      batch (#41).
- [ ] The palette tables (`colors`, `dark_colors`,
      `light_colors`) and the public surface (`M.setup`,
      `M.set_theme`, `M.toggle`, `M.subscribe`, `M.colors`,
      `M.dark_colors`, `M.light_colors`) are unchanged. The
      `subscribers` table, `subscribe`/`emit` registry,
      `os_theme.detect()` call site, `vim.o.background = theme`
      assignment, `vim.g.colors_name = "solarized"` write,
      `emit()` call, and `set_theme`/`toggle`'s
      `vim.g.colors_name = nil` clear are preserved.
- [ ] `tests/colors/highlights/base_spec.lua`,
      `tests/colors/highlights/syntax_spec.lua`, and
      `tests/colors/highlights/treesitter_spec.lua` each exist
      and exercise their module's `M.highlights(c)` as a pure
      function. Each spec has at least two cases: one asserting
      a representative entry per visual concern the section
      covers, one asserting the function is pure (calling twice
      returns equal-but-not-identical tables).
- [ ] `tests/colors/solarized_composition_spec.lua` is extended
      with at least one new case per new section: assert that
      `setup("dark")` records a representative entry from
      `base` (e.g., `Normal`), `syntax` (e.g., `Comment`), and
      `treesitter` (e.g., `["@function"]`), with the expected
      `dark_colors`-derived attributes. Existing cases (the
      `lsp_diagnostic` assertions, the inlined-rest probe, the
      trailing-manual-block probe) continue to pass — the
      inlined-rest probe is updated to assert an entry that is
      still in the inlined table after this batch (e.g.,
      `markdownH1` instead of the now-extracted `Normal` /
      `Comment`).
- [ ] `tests/colors/solarized_composition_spec.lua`'s
      `pre_case` and `post_case` clear `package.loaded` for the
      three new module paths in addition to the existing
      `colors.solarized`, `colors.highlights.lsp_diagnostic`,
      `colors.os_theme` clears.
- [ ] No edits to `lua/colors/os_theme.lua`,
      `lua/config/autocmds.lua`, `lua/plugins/lualine.lua`,
      `lua/config/commands.lua`,
      `lua/config/commands_registrar.lua`,
      `lua/utils/obsidian_cli/`, `lua/utils/wordcount.lua`, or
      `lua/utils/macos_codesign/`. Verified by `git diff`
      against the cycle base showing changes only under
      `lua/colors/solarized.lua`,
      `lua/colors/highlights/{base,syntax,treesitter}.lua`,
      `tests/colors/highlights/{base,syntax,treesitter}_spec.lua`,
      and `tests/colors/solarized_composition_spec.lua`.
- [ ] `./tests/run` exits 0 on the whole suite — including
      cycle 01, cycle 02, and cycle 03 (parents #22, #30, #32,
      and parent #38's prior tracer #39) specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 equivalent — the
      new specs do not depend on any external binary; the
      composition spec keeps its `vim.fn.has → 0` stub and its
      explicit `theme_override`.
- [ ] No reaching into module locals or monkey-patching
      internals beyond the sanctioned per-test
      `vim.api.nvim_set_hl` / `vim.cmd` / `vim.defer_fn` /
      `vim.fn.has` swaps.
- [ ] **Resolved-through-implementation decisions recorded in
      AAR:** section-partition refinement → three separate
      modules confirmed (or merge surfaced if implementation
      reveals a reason); `base` placed in the code-syntax batch
      vs. its own sub-issue → confirmed batched here unless the
      review pass surfaces a regression that argues for
      splitting.

## Proposed tests

Three new per-section specs plus an extension to the existing
composition spec.

### `tests/colors/highlights/base_spec.lua` — per-section, pure

No `pre_case` / `post_case` swaps required; the module is a
pure function.

Test cases:

1. `base.highlights returns Normal/NormalFloat/NormalNC with
   palette colors propagated` — pass a representative palette
   `{ fg0 = "#aaa", bg0 = "#000", bg1 = "#111" }`, assert
   `result.Normal.fg == "#aaa"`, `result.NormalFloat.bg == "#111"`.
2. `base.highlights returns the cursor cluster` — assert
   `result.Cursor`, `result.CursorLine`, `result.CursorColumn`,
   `result.CursorLineNr` are present with expected attributes.
3. `base.highlights returns the statusline cluster` — assert
   `result.StatusLine`, `result.StatusLineNC`, `result.StatusLineTerm`,
   `result.StatusLineTermNC` are present.
4. `base.highlights returns the messages cluster` — assert
   `result.ErrorMsg`, `result.WarningMsg`, `result.ModeMsg`,
   `result.MoreMsg`, `result.Question` are present.
5. `base.highlights is pure` — call twice, assert structural
   equality + table-identity inequality.

### `tests/colors/highlights/syntax_spec.lua` — per-section, pure

Test cases:

1. `syntax.highlights returns Comment with italic = true` —
   pass palette, assert `result.Comment.italic == true` and
   `result.Comment.fg == c.fg2`.
2. `syntax.highlights returns the constant cluster` — assert
   `result.Constant`, `result.String`, `result.Character`,
   `result.Number`, `result.Boolean`, `result.Float` all map
   to `c.cyan` for `fg`.
3. `syntax.highlights returns the type cluster` — assert
   `result.Type`, `result.StorageClass`, `result.Structure`,
   `result.Typedef` all use `c.yellow`.
4. `syntax.highlights returns Underlined/Bold/Italic with
   their attributes` — assert
   `result.Underlined.underline == true`,
   `result.Bold.bold == true`,
   `result.Italic.italic == true`.
5. `syntax.highlights is pure` — call twice, assert structural
   equality + table-identity inequality.

### `tests/colors/highlights/treesitter_spec.lua` — per-section, pure

Test cases:

1. `treesitter.highlights returns @function and @function.builtin
   with palette colors propagated` — assert
   `result["@function"].fg == c.blue`,
   `result["@function.builtin"].fg == c.blue`.
2. `treesitter.highlights returns the @text cluster` — assert
   `result["@text"]`, `result["@text.strong"].bold == true`,
   `result["@text.title"]`, `result["@text.literal"]` are
   present with expected attributes.
3. `treesitter.highlights returns the @tag and @punctuation
   clusters` — assert `result["@tag"]`,
   `result["@tag.delimiter"]`, `result["@punctuation"]`,
   `result["@punctuation.bracket"]`,
   `result["@punctuation.delimiter"]`,
   `result["@punctuation.special"]` are present.
4. `treesitter.highlights returns the rainbow-delimiter
   cluster` — assert `RainbowDelimiterRed`/`Yellow`/`Blue`/
   `Orange`/`Green`/`Violet`/`Cyan` are present and map to
   their respective palette accent colors.
5. `treesitter.highlights returns the @macro/@define/@include/
   @preproc cluster mapped to c.orange` — one assertion per key.
6. `treesitter.highlights is pure` — call twice, assert
   structural equality + table-identity inequality.

### `tests/colors/solarized_composition_spec.lua` — extension

Add three new cases (one per new section) and update the
inlined-rest probe to assert a still-inlined entry.

New cases:

1. `setup('dark') applies a representative base entry` —
   assert `_G.recorded_hls.StatusLine.fg == "#8faaab"`
   (base1 / fg1 in `dark_colors`),
   `_G.recorded_hls.StatusLine.bg == "#093946"` (base02 / bg1).
2. `setup('dark') applies a representative syntax entry` —
   assert `_G.recorded_hls.Comment.fg == "#657377"`
   (base00 / fg2 in `dark_colors`) and
   `_G.recorded_hls.Comment.italic == true`.
3. `setup('dark') applies a representative treesitter entry` —
   assert `_G.recorded_hls["@function"].fg == "#2b90d8"`
   (`c.blue`) and `_G.recorded_hls["@text.strong"].bold == true`.

Updated case:

- `setup('dark') applies a representative inlined entry` —
  switch the asserted entries from `Normal` / `Comment` (now
  extracted) to `markdownH1` (still inlined) and
  `["@markdown.heading"]` (still inlined). Assert
  `markdownH1.fg == "#2b90d8"` (`c.blue`) and
  `markdownH1.bold == true`.

`pre_case` / `post_case` updates:

- Add `package.loaded["colors.highlights.base"] = nil`,
  `package.loaded["colors.highlights.syntax"] = nil`,
  `package.loaded["colors.highlights.treesitter"] = nil` to
  both hooks alongside the existing clears.

The trailing-manual-block case (`javaScriptStringT` overwrite
assertion) stays as-is — the trailing block is preserved in
this sub-issue, so the assertion still holds.

## Affected artifacts

- **`lua/colors/highlights/base.lua`** — new file. ~35 lines.
- **`lua/colors/highlights/syntax.lua`** — new file. ~35 lines.
- **`lua/colors/highlights/treesitter.lua`** — new file. ~80
  lines.
- **`lua/colors/solarized.lua`**:
  - `SECTIONS` extended from one entry to four entries
    (`base`, `syntax`, `treesitter` appended after
    `lsp_diagnostic`).
  - Inlined `rest` table shrinks: remove the "Basic colors"
    through "Messages" block, the "Syntax highlighting" through
    `Italic` block, and the "Treesitter" through `["@preproc"]`
    block (including the rainbow-delimiter sub-block).
  - No other changes — the `compose` loops, the apply loop, and
    the trailing manual block stay byte-identical.
- **`tests/colors/highlights/base_spec.lua`** — new file.
- **`tests/colors/highlights/syntax_spec.lua`** — new file.
- **`tests/colors/highlights/treesitter_spec.lua`** — new file.
- **`tests/colors/solarized_composition_spec.lua`** — three
  new cases added; one existing case's asserted entries
  swapped to a still-inlined group; `pre_case` / `post_case`
  package-clear list extended.

No edits anywhere else.

## Dependencies

- **Sub-issue #39 closure** — established the section-module
  shape, the `SECTIONS` list, the inline `compose` loops, the
  composition spec pattern with `_G.recorded_hls`, and the
  `package.loaded` reload trick. This sub-issue applies that
  shape to three more sections and extends the spec verbatim.
- **Cycle 03 parent #22 (A) closure** — fake-the-API per-case
  swap pattern. Closed.
- **Cycle 03 parent #30 (D) closure** — public-interface-only
  test discipline. Closed.
- **Cycle 03 parent #32 (B) closure** — `vim.o.background`
  pin in `pre_case` to suppress the colorscheme-reapply path.
  Closed.
- **No dependency on later sub-issues under parent #38.** The
  markdown batch (#41) depends on this sub-issue's ordering
  decisions but is not blocked by anything novel here.
- **No dependency on later parents.** Parent #38 is the last
  parent in cycle 03's resolved sequencing.
