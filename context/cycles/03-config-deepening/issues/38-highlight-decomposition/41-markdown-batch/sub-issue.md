# Sub-issue #41 — Markdown batch (`markdown` + `treesitter_markdown` + `obsidian` + `template_literals`)

GitHub issue: #41. Third sub-issue under parent #38 (Candidate C —
`solarized.lua` highlight decomposition) of cycle
`03-config-deepening`.

## Description

Final extraction batch for parent #38. Extract the four remaining
sections from the inlined intermediate `rest` table into pure-function
section modules **and** fold the trailing manual `vim.api.nvim_set_hl`
block at the end of `setup()` into those same modules. After #41,
`setup()` has exactly one apply loop, the inlined `rest` table is
gone, and the trailing manual block is gone — the parent issue's
"no second imperative pass" structural AC becomes true.

The four new modules:

- `lua/colors/highlights/markdown.lua` — vim-default markdown groups:
  `markdownH1`–`H6`, `markdownHeadingDelimiter`/`HeadingRule`,
  `markdownBold`/`Italic`/`BoldItalic` and their delimiters,
  `markdownCode`/`CodeBlock`/`CodeDelimiter`/`InlineCode`,
  `markdownLink*`, `markdownUrl*`, `markdownListMarker*`,
  `markdownBlockquote*`, `markdownHr`/`Rule`, `markdownTable*`,
  `markdownStrikethrough*`, `markdownFootnote*`,
  `markdownAutomaticLink*`, `markdownEscape*`. Plus the trailing-block
  entries that augment the same family: `markdownMath`,
  `markdownMathDelimiter`, `markdownMathBlock`,
  `markdownMathBlockDelimiter`, `markdownTaskChecked`,
  `markdownTaskUnchecked`, `markdownDefinitionTerm`,
  `markdownDefinition`. The redundant trailing-block writes for
  `markdownCodeBlock` and `markdownInlineCode` collapse into the
  single canonical definition (same values; idempotent).

- `lua/colors/highlights/treesitter_markdown.lua` — `@markdown.*`
  treesitter capture groups: heading family
  (`@markdown.heading`, `.heading.1`–`.6`, `.heading.marker`),
  `@markdown.strong`/`emphasis`/`strong_emphasis`, code family
  (`code`, `code_block`, `inline_code`, `code_fence_content`,
  `code_fence`), link family (`link`, `link_text`, `link_url`,
  `link_label`, `link_destination`), list family (`list`,
  `list_marker`, `list_item`, `ordered_list`, `unordered_list`),
  quote family (`quote`, `block_quote`, `block_quote_marker`),
  rule family (`thematic_break`, `horizontal_rule`), table family
  (`table`, `table_head`, `table_row`, `table_cell`,
  `table_delimiter`), `strikethrough`, footnote family
  (`footnote`, `footnote_definition`, `footnote_reference`),
  frontmatter family (`frontmatter`, `frontmatter_delimiter`),
  escape family (`escape`, `escape_sequence`).

- `lua/colors/highlights/obsidian.lua` — Obsidian-specific markdown
  extensions in both legacy and treesitter flavors:
  `markdownWikiLink`/`WikiLinkText`, `markdownTag`, `markdownHashtag`,
  `markdownMention`, `markdownHighlight`, `markdownCallout`,
  `markdownCalloutTitle`, `@markdown.wiki_link`/`wiki_link_text`,
  `@markdown.tag`, `@markdown.hashtag`, `@markdown.mention`,
  `@markdown.highlight`, `@markdown.callout`,
  `@markdown.callout_title`. Plus the trailing-block entries
  `markdownEmbeddedCode` and `markdownEmbeddedCodeDelimiter`.

- `lua/colors/highlights/template_literals.lua` — JavaScript
  template-literal HTML embedding. Owns `javaScriptStringT` in its
  **final** form (`fg = c.cyan, bg = c.bg1`, the value the trailing
  manual block currently writes), the HTML cluster currently in
  `rest` (`htmlTag`, `htmlTagName`, `htmlArg`, `htmlString`,
  `htmlSpecialChar`, `htmlEndTag`, `htmlLink`, `htmlBold`,
  `htmlItalic`, `htmlUnderline`), and the `javaScriptStringT.html*`
  augmentation cluster from the trailing block
  (`.htmlTag`, `.htmlTagName`, `.htmlArg`, `.htmlString`,
  `.htmlSpecialChar`, `.htmlEndTag`).

After #41, the inlined `rest` table is removed from `setup()` and the
trailing manual `vim.api.nvim_set_hl` block (currently lines ~286–314
of `solarized.lua`) is removed. `setup()` reads end-to-end as: resolve
theme → set background → compose SECTIONS into `merged` → one apply
loop → set `colors_name` → `emit()`. This is the shape from parent
#38's implementation sketch.

## Dependency classification

Identical to #39 and #40 — no new dependencies introduced.

| Dependency | Category | Testing strategy |
| --- | --- | --- |
| `vim.api.nvim_set_hl` | True external (Neovim API) | Per-test recording fake established by #39's composition spec; reused. |
| `vim.cmd` / `vim.defer_fn` | True external | Per-test no-op fakes; reused. |
| `vim.fn.has` | True external | Stubbed to 0; defense-in-depth. |
| `colors.solarized` | In-process | Public `M.setup(theme_override)`. |
| `colors.highlights.markdown` / `treesitter_markdown` / `obsidian` / `template_literals` (new) | In-process | Public `M.highlights(c)`. Pure functions, no fakes needed. |
| `colors.highlights.lsp_diagnostic` / `base` / `syntax` / `treesitter` (existing) | In-process | Already exercised by their own specs; the composition spec keeps asserting one entry from each as a regression probe. |
| `colors.os_theme` | In-process; not exercised | `setup` is called with explicit `theme_override`. |

No new ports. Section modules remain pure Lua functions consuming a
palette table.

## Interface design

The section-module shape and composition-root shape were locked by
#39. The fresh design call this sub-issue makes is **override-pair
resolution** — how the current "definition in `rest`, overwrite in
trailing block" idiom maps onto the section-module world.

### Alternative A — single definition per group (proposed)

Each highlight group is defined exactly **once** across all section
modules. The "override pair" idiom collapses entirely:

- `template_literals.lua` defines `javaScriptStringT` in its final
  form (`fg = c.cyan, bg = c.bg1`, the cyan/bg1 value the trailing
  block currently writes). No other section module defines
  `javaScriptStringT`.
- `markdown.lua` defines `markdownCodeBlock` and `markdownInlineCode`
  exactly once each (the trailing block's redundant identical writes
  are collapsed into the single canonical definition).
- All other groups appear in exactly one module.

SECTIONS order has no semantic significance in this sub-issue — no
two modules share a key, so any total order produces the same
`merged` table. The chosen order
(`lsp_diagnostic`, `base`, `syntax`, `treesitter`, `markdown`,
`treesitter_markdown`, `obsidian`, `template_literals`) is a
read-order convention: UI-chrome and LSP first, code coloring next,
markdown family clustered together, with template-literals last
because it is the only section that augments highlights from another
domain (HTML embedded in JavaScript).

**Pros:** Each highlight group has one home; readers find a group by
domain, not by precedence chain. The composition root's last-module-
wins semantics is a fallback contract, not a load-bearing one. The
"intentional override" between `rest` and the trailing block —
which existed only because the trailing block ran after the inlined
table's apply loop — disappears, exposing what the override actually
encoded: `javaScriptStringT`'s real intended value is the cyan/bg1
form, and the inlined `{ fg = c.yellow }` was a stale leftover.
The redundant `markdownCodeBlock`/`markdownInlineCode` writes
collapse cleanly because they were always idempotent.

**Cons:** The composition spec loses one signal — the
"trailing-block-overwrites-rest" probe asserting
`javaScriptStringT.fg == "#259d94"` (cyan, not yellow). Replaced by
a `template_literals`-section probe asserting the same final value
from the new owning module, which is the post-#41 contract.

### Alternative B — preserve override-pair idiom across modules

Keep the "intentional override" pattern: one section defines the
default, another defines the override, SECTIONS order chooses the
winner.

- A markdown-or-html section defines `javaScriptStringT = { fg = c.yellow }`.
- `template_literals.lua`, listed later in SECTIONS, defines
  `javaScriptStringT = { fg = c.cyan, bg = c.bg1 }`, winning the merge.

**Pros:** Exercises SECTIONS ordering precedence in the sub-issue's
test matrix; preserves the visible "override pair" idiom for any
future maintainer who reads the inlined-table-era code.

**Cons:** Reproduces a code-organization quirk that existed only
because the apply phase ran twice. With one apply phase, defining
`javaScriptStringT` twice is an obfuscation: the reader has to scan
SECTIONS, identify which modules define the key, reason about order,
and then conclude the cyan/bg1 form wins. Defining it once where it
domain-belongs (template_literals) is strictly clearer. The
override-pair idiom is also a poor fit for `javaScriptStringT`'s
domain — the group is JavaScript template-literal text, not a
markdown group, so giving its "default" to a markdown section is
itself a misclassification.

### Alternative C — preserve idiom only for the redundant pair

Apply Alternative A to `javaScriptStringT` (template_literals owns
the final form alone) but preserve Alternative B for
`markdownCodeBlock`/`markdownInlineCode` — `markdown.lua` defines
them and `template_literals.lua` (or some other later section)
re-defines them identically as a "this value is contract" signal.

**Pros:** Keeps an explicit redundant-write signal that
`markdownCodeBlock`/`markdownInlineCode` are sensitive to override
order in case future code adds a competing definition.

**Cons:** No actual override exists — both writes set the same
value. The "redundant write as documentation" is inferior to a
single definition with a one-line comment if a comment is even
needed. Rejected.

### Chosen (proposed; final in AAR)

**Alternative A.** Single definition per group across all section
modules. SECTIONS order is a read-order convention only; no two
modules share a key.

**Reason for A:** The override-pair idiom in the pre-#41 code was a
phase-ordering artifact, not a design intent. Once `setup()` has one
apply loop, defining each group exactly once where it
domain-belongs makes the section modules act as the intended unit of
review (parent #38's user story 3 — edit one section, run one spec).
Last-module-wins remains the merge contract for safety, but no
in-tree code exercises it.

**Rejected B:** preserves a phase-ordering artifact and
misclassifies `javaScriptStringT` into a markdown section.

**Rejected C:** the redundant-write idiom encodes nothing; a comment
is cheaper than a duplicate definition.

### Public interface (post-sub-issue)

```lua
-- lua/colors/highlights/markdown.lua
local M = {}
function M.highlights(c)
  return {
    markdownH1                 = { fg = c.blue, bold = true },
    markdownH2                 = { fg = c.blue, bold = true },
    -- ... ~58 markdown* legacy entries (heading, bold/italic, code,
    --     link, list, blockquote, rule, table, strikethrough,
    --     footnote, automaticlink, escape, math, task, definition)
    markdownDefinition         = { fg = c.fg0 },
  }
end
return M
```

```lua
-- lua/colors/highlights/treesitter_markdown.lua
local M = {}
function M.highlights(c)
  return {
    ["@markdown.heading"]      = { fg = c.blue, bold = true },
    -- ... ~50 @markdown.* entries (heading, strong/emphasis, code,
    --     link, list, quote, rule, table, strikethrough, footnote,
    --     frontmatter, escape)
    ["@markdown.escape_sequence"] = { fg = c.magenta },
  }
end
return M
```

```lua
-- lua/colors/highlights/obsidian.lua
local M = {}
function M.highlights(c)
  return {
    markdownWikiLink            = { fg = c.violet, underline = true },
    -- ... 18 entries: 8 markdown* obsidian extensions,
    --     8 @markdown.* obsidian extensions, 2 markdownEmbeddedCode*
    markdownEmbeddedCodeDelimiter = { fg = c.fg2 },
  }
end
return M
```

```lua
-- lua/colors/highlights/template_literals.lua
local M = {}
function M.highlights(c)
  return {
    javaScriptStringT          = { fg = c.cyan, bg = c.bg1 },
    htmlTag                    = { fg = c.magenta },
    -- ... 17 entries total: javaScriptStringT (final form),
    --     10 html* entries, 6 javaScriptStringT.html* augmentations
    ["javaScriptStringT.htmlEndTag"] = { fg = c.magenta, bold = true },
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
  "colors.highlights.markdown",
  "colors.highlights.treesitter_markdown",
  "colors.highlights.obsidian",
  "colors.highlights.template_literals",
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

  for group, opts in pairs(merged) do
    vim.api.nvim_set_hl(0, group, opts)
  end

  vim.g.colors_name = "solarized"
  emit()
end
```

`solarized.lua`'s public surface (`M.setup`, `M.set_theme`,
`M.toggle`, `M.subscribe`, `M.colors`, `M.dark_colors`,
`M.light_colors`) is unchanged. The `subscribers` registry, `emit`,
`os_theme.detect()` call site, `vim.o.background` assignment,
`vim.g.colors_name` write, `emit()` call, and `set_theme`/`toggle`
are all preserved.

## Acceptance criteria

- [ ] `lua/colors/highlights/markdown.lua` exists, returns a module
      with `M.highlights(c) → table`, contains zero `vim.*`
      references. Verified by
      `grep -n 'vim\.' lua/colors/highlights/markdown.lua` returning
      zero matches.
- [ ] `lua/colors/highlights/treesitter_markdown.lua`,
      `lua/colors/highlights/obsidian.lua`, and
      `lua/colors/highlights/template_literals.lua` exist with the
      same shape and the same zero-`vim.*` invariant.
- [ ] The four new section modules' returned tables, taken together
      with the four already-extracted modules
      (`lsp_diagnostic`, `base`, `syntax`, `treesitter`), contain
      every highlight group that the pre-#41 `setup()` writes —
      whether it came from the inlined `rest` table or from the
      trailing manual `nvim_set_hl` block. Verified by reading the
      pre-#41 `setup()` against the post-#41 union of section-module
      outputs and confirming no group is dropped.
- [ ] Every group's final attribute table is preserved. Specifically:
      `javaScriptStringT` is `{ fg = c.cyan, bg = c.bg1 }` (the
      trailing-block value, not the stale `{ fg = c.yellow }` from
      the inlined `rest`); `markdownCodeBlock` and `markdownInlineCode`
      are `{ fg = c.cyan, bg = c.bg1 }` (one canonical write each, not
      two redundant writes); all other groups carry their pre-#41
      values verbatim.
- [ ] No section module shares a highlight-group key with any other
      section module. Verified by reading each module against the
      others and confirming the union of their key-sets has no
      duplicates. SECTIONS order is read-order convention; no merge
      precedence is exercised by the in-tree section modules.
- [ ] `lua/colors/solarized.lua`'s `SECTIONS` table-local contains
      exactly eight entries in this order:
      `"colors.highlights.lsp_diagnostic"`,
      `"colors.highlights.base"`,
      `"colors.highlights.syntax"`,
      `"colors.highlights.treesitter"`,
      `"colors.highlights.markdown"`,
      `"colors.highlights.treesitter_markdown"`,
      `"colors.highlights.obsidian"`,
      `"colors.highlights.template_literals"`.
- [ ] The inlined `rest` table is removed from `setup()`. The
      `for group, opts in pairs(rest) do merged[group] = opts end`
      loop is removed. `setup()`'s body between resolving `c` and
      writing `colors_name` consists of: `vim.o.background = theme`,
      the SECTIONS compose loop into `merged`, the single apply
      loop, and nothing else.
- [ ] The trailing manual `vim.api.nvim_set_hl` block (currently
      lines ~286–314 of `solarized.lua`) is removed. Every entry
      that block defined has folded into one of the four new
      section modules per the partition above.
- [ ] `setup()` contains exactly one `vim.api.nvim_set_hl` call —
      the call inside the apply loop. Verified by
      `grep -n 'nvim_set_hl' lua/colors/solarized.lua` returning
      exactly one match.
- [ ] The palette tables (`colors`, `dark_colors`, `light_colors`)
      and the public surface (`M.setup`, `M.set_theme`, `M.toggle`,
      `M.subscribe`, `M.colors`, `M.dark_colors`, `M.light_colors`)
      are unchanged. The `subscribers` table, `subscribe`/`emit`
      registry, `os_theme.detect()` call site,
      `vim.o.background = theme` assignment,
      `vim.g.colors_name = "solarized"` write, `emit()` call, and
      `set_theme`/`toggle`'s `vim.g.colors_name = nil` clear are
      preserved.
- [ ] `tests/colors/highlights/markdown_spec.lua`,
      `tests/colors/highlights/treesitter_markdown_spec.lua`,
      `tests/colors/highlights/obsidian_spec.lua`, and
      `tests/colors/highlights/template_literals_spec.lua` each
      exist and exercise their module's `M.highlights(c)` as a pure
      function. Each spec has at least two cases: one asserting at
      least one representative entry per visual concern the section
      covers, one asserting the function is pure (calling twice
      returns equal-but-not-identical tables — using
      `MiniTest.expect.equality(rawequal(r1, r2), false)` per #39's
      AAR carry-forward).
- [ ] `tests/colors/solarized_composition_spec.lua` is extended
      with at least one new representative-entry case per new
      section: `markdown` (e.g., `markdownH1`), `treesitter_markdown`
      (e.g., `["@markdown.heading"]`), `obsidian` (e.g.,
      `markdownWikiLink`), `template_literals` (e.g.,
      `javaScriptStringT` in its final cyan/bg1 form). Existing
      representative-entry cases for `lsp_diagnostic`, `base`,
      `syntax`, and `treesitter` continue to pass unchanged.
- [ ] The "inlined-rest probe" case in the composition spec
      (asserts `markdownH1`) is **renamed and re-purposed**: it
      now asserts a `markdown` section entry through the new
      module, since the inlined `rest` table no longer exists. The
      assertion values stay identical (markdownH1 is still
      `{ fg = c.blue, bold = true }`); only the case name and the
      docstring change to reflect the new ownership.
- [ ] The "trailing manual block" case in the composition spec
      (asserts `javaScriptStringT.fg == "#259d94"` and
      `.bg == "#093946"`) is **renamed and re-purposed**: it now
      asserts a `template_literals` section entry. The assertion
      values are unchanged (the canonical
      `{ fg = c.cyan, bg = c.bg1 }` form survives the fold).
- [ ] `tests/colors/solarized_composition_spec.lua`'s `pre_case`
      and `post_case` clear `package.loaded` for the four new
      module paths in addition to the existing clears.
- [ ] No edits to `lua/colors/os_theme.lua`,
      `lua/config/autocmds.lua`, `lua/plugins/lualine.lua`,
      `lua/config/commands.lua`,
      `lua/config/commands_registrar.lua`,
      `lua/utils/obsidian_cli/`, `lua/utils/wordcount.lua`, or
      `lua/utils/macos_codesign/`. Verified by `git diff` against
      the cycle base showing changes only under
      `lua/colors/solarized.lua`,
      `lua/colors/highlights/{markdown,treesitter_markdown,obsidian,template_literals}.lua`,
      `tests/colors/highlights/{markdown,treesitter_markdown,obsidian,template_literals}_spec.lua`,
      and `tests/colors/solarized_composition_spec.lua`.
- [ ] `./tests/run` exits 0 on the whole suite — including cycle
      01, cycle 02, and cycle 03 (parents #22, #30, #32, parent
      #38's prior sub-issues #39 and #40) specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 equivalent — the
      new specs do not depend on any external binary; the
      composition spec keeps its `vim.fn.has → 0` stub and its
      explicit `theme_override`.
- [ ] No reaching into module locals or monkey-patching internals
      beyond the sanctioned per-test
      `vim.api.nvim_set_hl` / `vim.cmd` / `vim.defer_fn` /
      `vim.fn.has` swaps.
- [ ] **Resolved-through-implementation decisions recorded in
      AAR:** override-pair handling → Alternative A (single
      definition per group) confirmed, or deviation surfaced if the
      design pass found a case where two modules genuinely need to
      share a key; section-partition refinement → four separate
      modules confirmed unless implementation surfaces a reason to
      merge or split.

## Proposed tests

Four new per-section specs plus updates to the existing composition
spec.

### `tests/colors/highlights/markdown_spec.lua` — per-section, pure

No `pre_case` / `post_case` swaps required; the module is a pure
function.

Test cases:

1. `markdown.highlights returns the heading cluster` — pass a
   representative palette
   `{ blue = "#2b90d8", fg2 = "#657377" }` (other keys included
   per actual usage), assert `result.markdownH1.fg == "#2b90d8"`,
   `.bold == true`; assert `markdownH2`–`H6` carry the same
   attribute pair; assert
   `result.markdownHeadingDelimiter.fg == "#657377"`.
2. `markdown.highlights returns the code cluster, canonical
   definition` — assert `result.markdownCode`,
   `result.markdownCodeBlock`, `result.markdownInlineCode` all
   equal `{ fg = c.cyan, bg = c.bg1 }`; assert
   `result.markdownCodeDelimiter.fg == c.fg2`.
3. `markdown.highlights returns the link/url cluster` — assert
   `result.markdownLink.underline == true`, `.fg == c.blue`;
   assert `markdownUrl`, `markdownUrlTitle`,
   `markdownAutomaticLink` are present with expected attributes.
4. `markdown.highlights returns the list/blockquote/table cluster`
   — assert `result.markdownListMarker.fg == c.green`;
   `result.markdownBlockquote.italic == true`;
   `result.markdownTable`, `markdownTableHead`,
   `markdownTableDelimiter` are present.
5. `markdown.highlights returns the math/task/definition cluster
   folded from the trailing block` — assert `result.markdownMath`,
   `markdownMathBlock`, `markdownTaskChecked`,
   `markdownTaskUnchecked`, `markdownDefinitionTerm`,
   `markdownDefinition` are present with expected attributes.
6. `markdown.highlights is pure` — call twice, assert structural
   equality + `rawequal(r1, r2) == false`.

### `tests/colors/highlights/treesitter_markdown_spec.lua` — per-section, pure

Test cases:

1. `treesitter_markdown.highlights returns the heading family` —
   assert `result["@markdown.heading"]`,
   `["@markdown.heading.1"]`–`.6`, and `.heading.marker` are
   present with expected attributes.
2. `treesitter_markdown.highlights returns the code family` —
   assert `result["@markdown.code"]`, `.code_block`,
   `.inline_code`, `.code_fence_content` all equal
   `{ fg = c.cyan, bg = c.bg1 }`; `.code_fence.fg == c.fg2`.
3. `treesitter_markdown.highlights returns the link family` —
   assert `["@markdown.link"]`, `.link_text`, `.link_url`,
   `.link_label`, `.link_destination` are present with expected
   attributes.
4. `treesitter_markdown.highlights returns the list/quote/table
   family` — assert `["@markdown.list"]`, `.list_marker`,
   `["@markdown.quote"]`, `.block_quote`, `["@markdown.table"]`,
   `.table_head`, `.table_delimiter` are present.
5. `treesitter_markdown.highlights returns frontmatter and escape
   families` — assert `["@markdown.frontmatter"]`,
   `.frontmatter_delimiter`, `["@markdown.escape"]`,
   `.escape_sequence` are present.
6. `treesitter_markdown.highlights is pure` — call twice, assert
   structural equality + `rawequal(r1, r2) == false`.

### `tests/colors/highlights/obsidian_spec.lua` — per-section, pure

Test cases:

1. `obsidian.highlights returns wiki-link entries in both flavors`
   — assert `result.markdownWikiLink.fg == c.violet`,
   `.underline == true`; assert `result["@markdown.wiki_link"]`
   carries the same attributes; assert `markdownWikiLinkText` and
   `["@markdown.wiki_link_text"]` likewise.
2. `obsidian.highlights returns tag/hashtag/mention/highlight in
   both flavors` — assert `markdownTag.fg == c.orange`,
   `["@markdown.tag"]`, `markdownHashtag`, `markdownMention`,
   `markdownHighlight`, and their `@markdown.*` counterparts.
3. `obsidian.highlights returns callout entries` — assert
   `markdownCallout`, `markdownCalloutTitle`,
   `["@markdown.callout"]`, `["@markdown.callout_title"]` are
   present with expected attributes.
4. `obsidian.highlights returns the embedded-code cluster folded
   from the trailing block` — assert `result.markdownEmbeddedCode`
   `{ fg = c.cyan, bg = c.bg1 }` and
   `markdownEmbeddedCodeDelimiter.fg == c.fg2`.
5. `obsidian.highlights is pure` — call twice, assert structural
   equality + `rawequal(r1, r2) == false`.

### `tests/colors/highlights/template_literals_spec.lua` — per-section, pure

Test cases:

1. `template_literals.highlights returns javaScriptStringT in its
   final form` — assert `result.javaScriptStringT.fg == c.cyan`
   and `.bg == c.bg1` (the cyan/bg1 form, not the stale yellow
   form from the pre-#41 inlined `rest`). This test is the
   regression guard for the override-pair fold.
2. `template_literals.highlights returns the html cluster` —
   assert `result.htmlTag.fg == c.magenta`, `htmlTagName`,
   `htmlArg`, `htmlString`, `htmlSpecialChar`, `htmlEndTag`,
   `htmlLink`, `htmlBold`, `htmlItalic`, `htmlUnderline` are
   present with expected attributes.
3. `template_literals.highlights returns the
   javaScriptStringT.html* augmentation cluster` — assert
   `result["javaScriptStringT.htmlTag"]`, `.htmlTagName`,
   `.htmlArg`, `.htmlString`, `.htmlSpecialChar`, `.htmlEndTag`
   are present with expected attributes (e.g.,
   `["javaScriptStringT.htmlEndTag"].fg == c.magenta`,
   `.bold == true`).
4. `template_literals.highlights is pure` — call twice, assert
   structural equality + `rawequal(r1, r2) == false`.

### `tests/colors/solarized_composition_spec.lua` — extension

Add four new representative-entry cases (one per new section) and
re-purpose the two cases whose anchors no longer reflect the
post-#41 layout.

New cases:

1. `setup('dark') applies a representative markdown entry` —
   assert `_G.recorded_hls.markdownH1.fg == "#2b90d8"` (`c.blue`)
   and `markdownH1.bold == true`.
2. `setup('dark') applies a representative treesitter_markdown
   entry` — assert
   `_G.recorded_hls["@markdown.heading"].fg == "#2b90d8"` and
   `.bold == true`.
3. `setup('dark') applies a representative obsidian entry` —
   assert `_G.recorded_hls.markdownWikiLink.fg == "#7d80d1"`
   (`c.violet`) and `.underline == true`.
4. `setup('dark') applies a representative template_literals
   entry` — assert `_G.recorded_hls.htmlTag.fg == "#dd459d"`
   (`c.magenta`).

Re-purposed cases (same assertions, new names/docstrings):

- `setup('dark') applies a representative inlined entry` →
  rename to `setup('dark') applies a markdown section entry` (the
  `markdownH1` assertion stays — but this case now provides
  defense-in-depth alongside the new markdown case; **delete this
  one** as a duplicate. The new case 1 above replaces it.)
- `setup('dark') still applies the trailing manual block` →
  rename to `setup('dark') applies the template_literals override
  for javaScriptStringT`. Assertion values
  (`fg == "#259d94"`, `bg == "#093946"`) are unchanged — the
  cyan/bg1 form survives the fold as the canonical definition.
  Docstring updates to reflect that the fold preserved the value
  rather than the trailing-block phase preserving it.

`pre_case` / `post_case` updates:

- Add `package.loaded["colors.highlights.markdown"] = nil`,
  `package.loaded["colors.highlights.treesitter_markdown"] = nil`,
  `package.loaded["colors.highlights.obsidian"] = nil`,
  `package.loaded["colors.highlights.template_literals"] = nil` to
  both hooks alongside the existing clears.

The lsp_diagnostic dark/light cases stay as-is (they are
parent-#38 closure signals — every section module reachable
through `setup()` for both palettes). The base/syntax/treesitter
cases stay as-is (sub-issue #40 closure signals).

## Affected artifacts

- **`lua/colors/highlights/markdown.lua`** — new file. ~65 lines
  (~58 entries plus boilerplate).
- **`lua/colors/highlights/treesitter_markdown.lua`** — new file.
  ~55 lines (~50 entries plus boilerplate).
- **`lua/colors/highlights/obsidian.lua`** — new file. ~25 lines
  (18 entries plus boilerplate).
- **`lua/colors/highlights/template_literals.lua`** — new file.
  ~25 lines (17 entries plus boilerplate).
- **`lua/colors/solarized.lua`**:
  - `SECTIONS` extended from four entries to eight entries
    (markdown, treesitter_markdown, obsidian, template_literals
    appended).
  - Inlined `rest` table removed entirely along with its
    `for group, opts in pairs(rest) do merged[group] = opts end`
    loop.
  - Trailing manual `vim.api.nvim_set_hl` block (currently lines
    ~286–314) removed entirely.
  - `setup()` body between resolving `c` and writing
    `colors_name` consists of: `vim.o.background = theme`, the
    SECTIONS compose loop, the single apply loop. Nothing else.
- **`tests/colors/highlights/markdown_spec.lua`** — new file.
- **`tests/colors/highlights/treesitter_markdown_spec.lua`** —
  new file.
- **`tests/colors/highlights/obsidian_spec.lua`** — new file.
- **`tests/colors/highlights/template_literals_spec.lua`** — new
  file.
- **`tests/colors/solarized_composition_spec.lua`** — four new
  cases added; two existing cases re-purposed (one renamed,
  assertions unchanged; the inlined-rest probe removed as a
  duplicate of the new markdown case); `pre_case` / `post_case`
  package-clear list extended with four new module paths.

No edits anywhere else.

## Dependencies

- **Sub-issue #40 closure** — established the four-section
  SECTIONS list, the inline `compose` + `rest` apply pattern this
  sub-issue collapses, and the duplicate-key audit note for
  `@markdown.*` entries (see #40 AAR carry-forward).
- **Sub-issue #39 closure** — established the section-module
  shape, the `_G.recorded_hls` composition spec pattern, the
  `package.loaded` reload trick, and the
  `MiniTest.expect.equality(rawequal(r1, r2), false)` purity
  idiom.
- **Cycle 03 parent #22 (A) closure** — fake-the-API per-case
  swap pattern. Closed.
- **Cycle 03 parent #30 (D) closure** — public-interface-only
  test discipline. Closed.
- **Cycle 03 parent #32 (B) closure** — `vim.o.background` pin
  in `pre_case` to suppress the colorscheme-reapply path. Closed.
- **Closing sub-issue (#42) — depends on this one.** Parent #38's
  closure sub-issue verifies post-#41 state (eight section
  modules, no `rest`, no trailing block, exactly one
  `nvim_set_hl` call), resolves the composition-test-depth
  decision (cycle PRD open question #5), and records the
  ADR-0004 carry-forward note for the cycle 03 PRD close. #41
  must close before #42 begins.
- **No dependency on later parents.** Parent #38 is the last
  parent in cycle 03's resolved sequencing.
