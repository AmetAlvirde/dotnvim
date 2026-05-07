## Sub-PRD — `solarized.lua` highlight decomposition (Candidate C)

> Translated to `issue.md`. This sub-PRD records the product-level intent --
> user stories and dependencies. Update `issue.md` for ongoing technical work.
> Update this file only if the underlying user stories themselves change.

Fourth and final parent issue of cycle `03-config-deepening`, per the
resolved sequencing in the cycle PRD's open question #1
(A → D → B → C). Carries the cycle PRD's Candidate C goal —
decomposing the single ~340-entry highlight table currently inlined
inside `solarized.setup()` into named section modules, each exposing
`highlights(c) → table`, each unit-testable in isolation, with
`setup()` becoming a composition root that merges them and applies
the result.

## Scope

Split the highlights inlined inside `lua/colors/solarized.lua`'s
`setup()` body — currently one literal table from line ~111 to
line ~455, plus the trailing manual `vim.api.nvim_set_hl` calls at
lines ~462–491 — into a directory of section modules under
`lua/colors/highlights/`. Each section module exposes
`M.highlights(c) → table` as a pure function: it consumes the
resolved palette table (`dark_colors` or `light_colors`) and returns
the highlight-group map for that section, with no side effects and
no `vim.*` dependencies.

`solarized.setup()` is reshaped into a composition root: it resolves
the palette as today, requires each section module, calls
`section.highlights(c)` on each, merges their returned tables, and
applies the merged result via one `vim.api.nvim_set_hl` loop. The
trailing manual `vim.api.nvim_set_hl` calls at lines ~462–491 are
folded into the appropriate section modules — they are not preserved
as a second imperative pass after the composition.

The candidate sections — final naming and grouping decided in the
first sub-issue — follow the visual divisions already present in the
inlined table:

- **base** — Normal/NormalFloat/NormalNC, Cursor, line numbers,
  StatusLine, TabLine, Windows, Search, Visual, Diff, Folding,
  SignColumn, ColorColumn, Pmenu, Messages.
- **syntax** — vim-default syntax groups: Comment, Constant,
  Identifier, Statement, PreProc, Type, Special, Underlined, Bold,
  Italic.
- **lsp_diagnostic** — LspReferenceText/Read/Write,
  DiagnosticError/Warn/Info/Hint.
- **template_literals** — javaScriptStringT and the
  `javaScriptStringT.*` augmentation pass currently split between
  the highlights table and the manual nvim_set_hl block.
- **treesitter** — `@`-prefixed groups for general code: comment,
  string, function, parameter, type, keyword, variable, constant,
  text, tag, punctuation, plus rainbow delimiters and the
  `@macro`/`@define`/`@include`/`@preproc` cluster.
- **markdown** — `markdown*` legacy groups (H1–H6, Bold/Italic,
  Code, Link, List, Blockquote, Hr, Table, Footnote,
  AutomaticLink, Escape, Strikethrough), plus the trailing manual
  nvim_set_hl entries that augment the same groups (markdownMath,
  markdownTask, markdownDefinition, markdownCodeBlock /
  markdownInlineCode contrast overrides).
- **treesitter_markdown** — `@markdown.*` groups (heading, code,
  link, list, quote, table, footnote, frontmatter, escape, etc.).
- **obsidian** — wiki-link, hashtag, mention, highlight, callout
  groups in both `markdown*` and `@markdown.*` flavors, plus
  `markdownEmbeddedCode` / `markdownEmbeddedCodeDelimiter`.

The section names above are a working list, not a contract. The
first sub-issue resolves the final grouping; if a section turns out
to be too small or too large, it is split or merged in that
sub-issue's design pass and recorded in its AAR.

The 18 user commands keep their names and argument shapes. The
three `:Solarized*` commands keep their observable behavior — the
statusline, syntax, markdown, and Obsidian highlights all render as
they do today. The internal mechanism (one literal table vs. a
composed result) collapses; the externally observable highlight
output does not.

Out of scope for this parent issue:

- Adding new highlight groups, new theme variants, or new color
  values. Cycle PRD non-goal #3.
- Changing the palette tables (`colors`, `dark_colors`,
  `light_colors`). They stay where they are in `solarized.lua`.
- Reshaping `solarized.subscribe`, `os_theme`, `set_theme`,
  `toggle`, or `M.setup`'s public signature. Parent #32 closed those
  surfaces; C consumes them through their existing public shape.
- Touching `lua/colors/os_theme.lua`. It was extracted in #35 and
  is in its final shape for cycle 03.
- Touching `lua/config/autocmds.lua` or `lua/plugins/lualine.lua`.
  C's reshape is contained to `lua/colors/solarized.lua` and the new
  `lua/colors/highlights/` directory.
- Reshaping `lua/config/commands.lua` or any leaf module under
  `lua/utils/`. Parents #22 and #30 closed those surfaces.
- Generalizing the section-module pattern across the configuration.
  C's section modules serve `solarized.lua`. If a future colorscheme
  adopts the same shape, that is a future cycle's call.
- Promoting any section module to `lua/utils/`. Section modules are
  consumers of the solarized palette; they live next to it under
  `lua/colors/highlights/` and stay there.

## User stories

From the cycle PRD (story 3):

> As a maintainer tweaking the markdown highlight section, I want
> to edit one section module and have its tests exercise only that
> section, so that the change is local and the diff is reviewable.

From the cycle PRD (story 5, sub-slice):

> As a maintainer running the test suite headlessly, I want each
> extracted seam (highlight sections) to be exercised by at least
> one unit test against `./tests/run`, so that a regression in any
> of these surfaces cannot reach the configuration silently.

From the cycle PRD (story 6, sub-slice):

> As a maintainer of the wiring files at cycle close, I want
> `lua/colors/solarized.lua` to read top-to-bottom as a declarative
> spine — palette, subscribe seam, composition root, public surface
> — so that the file's purpose is visible without reading 350 lines
> of highlight-group entries inlined inside `setup()`.

## Dependencies

### On other sub-PRDs of cycle 03

- **Parent #22 (A) closure** — established the per-test fake-the-API
  pattern (swap a `vim.api.*` call for a fake in `pre_case`, restore
  in `post_case`). C reuses that pattern for the composition test
  that asserts the merged highlight set. Closed.
- **Parent #30 (D) closure** — proved the discipline of not reaching
  into module locals beyond sanctioned setter seams. Section modules
  are required-and-called through their public `M.highlights(c)`
  surface. Closed.
- **Parent #32 (B) closure** — established the post-`setup()` shape
  this parent inherits: `subscribe`/`emit` is in place, `os_theme`
  is extracted, `set_theme` and `toggle` clear `vim.g.colors_name`
  before re-entering `setup()`. C does not touch those code paths;
  it only reshapes the highlights composed inside `setup()`. The
  carry-forward note from #32's AAR — that `os_theme.detect()` is
  the call site in `setup()` — applies if C's composition root needs
  to interleave with that resolution. Closed.

### Files in scope

- **`lua/colors/solarized.lua`** — `setup()` body shrinks from the
  ~340-entry literal table + trailing manual nvim_set_hl block to a
  composition root that requires the section modules, calls
  `highlights(c)` on each, merges, and applies. Palette tables
  (`colors`, `dark_colors`, `light_colors`), `subscribe`/`emit`,
  `set_theme`, `toggle`, and the public `M.*` surface are unchanged.
- **`lua/colors/highlights/`** — new directory. Owned entirely by
  this parent. Contains one Lua module per section, each exposing
  `M.highlights(c) → table`. The exact files are decided in the
  first sub-issue's design pass and recorded in its AAR.
- **`tests/colors/highlights/`** — new directory. One spec per
  section module exercising `highlights(c)` as a pure function.
  Plus a composition-level spec exercising `setup()`'s merged
  output (closure signal per cycle PRD constraint #6).

### External dependencies (carried from the cycle PRD)

- **Cycle 01 closure** — `mini.test` harness in place at
  `./tests/run`. Already closed.
- **Cycle 02 closure** — out of scope for direct consumption. C does
  not import from `lua/utils/obsidian_cli/`.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `38-highlight-decomposition` tracks
  GitHub issue #38; sub-issues take sequential GitHub numbers.
- **ADR-0003** — does not bind C. Section modules are pure (no
  shell, no `vim.*` calls), so the four-layer subpackage shape does
  not apply. Recorded explicitly so the absence of an ADR-0003
  layout is not read as an oversight.

## Resolved decisions that bind this sub-PRD's scope

- **Section modules are pure (`highlights(c) → table`)**:
  no `vim.*` calls, no `require` cycles, no closure over palette
  tables. The palette is the single argument; the return is the
  group map for that section. This is what makes the per-section
  unit test fast and isolated.
- **`setup()` is the composition root**: the only place that
  resolves the palette, requires section modules, merges their
  output, and applies via `vim.api.nvim_set_hl`. No section module
  applies highlights itself.
- **No second imperative pass**: the trailing manual
  `vim.api.nvim_set_hl` calls currently outside the highlights table
  fold into section modules. After C, `setup()` has exactly one
  apply loop.
- **No public-surface change**: `M.setup`, `M.set_theme`, `M.toggle`,
  `M.subscribe`, `M.colors`, `M.dark_colors`, `M.light_colors`
  retain their current shape and observable behavior.
- **Highlight output is preserved** (cycle PRD constraint #6): the
  set of `:hi` groups defined after `setup()` runs is the same
  before and after C. A composition-level spec that asserts a
  stable subset of the merged table is the closure signal.

## Resolve-through-implementation items carried forward

- **Section grouping (cycle PRD goal C)**: the final partition of
  highlight groups into section modules — names, count, and
  membership — is decided in the first sub-issue's design pass.
  The list under "Scope" above is a starting partition; the first
  sub-issue refines it and records the resolution in its AAR.
- **Composition-test depth (cycle PRD open question #5)**:
  whether the composition-level spec asserts a stable
  whole-table snapshot or only a representative subset is decided
  during C. The risk is per-section tests passing while
  composition order regresses; a snapshot catches it but is
  churnier. Default expectation: a representative-subset spec
  covering one entry from each section and the
  template-literals/markdown override pairs (the only places where
  a section's later entries currently overwrite an earlier
  section's entry). Promotion to a full-table snapshot deferred
  unless implementation surfaces a regression the subset spec
  missed.
- **Override semantics**: when two section modules return the same
  highlight-group key (e.g., `markdownCodeBlock` appears in both
  the markdown section and a contrast-override block in the
  current code), the composition root needs a deterministic merge
  order. The first sub-issue resolves whether this is "last
  module wins" (preserves current behavior of the trailing manual
  nvim_set_hl block overwriting earlier entries) or "no two
  sections share keys" (forces the override-pair to be a single
  augmented section module). Recorded in the first sub-issue's
  AAR.

## Out of scope (carried from cycle PRD)

- Any cross-cycle coupling. C is the last parent in the resolved
  sequencing; no other parent depends on C.
- Touching highlight groups not currently defined in
  `solarized.lua`. C reshapes existing surfaces; it does not add
  new groups.
- Promoting the section-module pattern to `lua/utils/` or to a
  shared "colorscheme DSL." Section modules are scoped to the
  solarized colorscheme.
- `mini.test.new_child_neovim` for any C spec. Section modules are
  pure; the composition test fakes `vim.api.nvim_set_hl` per the
  cycle's established pattern. No live editor session is required
  to close C.
- ADR-0004 candidate evaluation. The cycle PRD defers that to
  PRD close, which happens after C closes — not as part of C
  itself.

## Domain validation pass

No new domain terms introduced by this sub-PRD. The terms used
here — **section module**, **composition root**, **highlight
group** — are pattern-language for module architecture and Neovim
domain vocabulary already covered by the cycle PRD's
domain-validation pass. Excluded from `ubiquitous-language.md` per
its policy on general programming and Neovim concepts.
