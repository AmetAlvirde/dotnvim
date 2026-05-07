# Parent Issue — `solarized.lua` highlight decomposition (Candidate C)

GitHub issue: #38. Fourth and final parent of cycle
`03-config-deepening`, landing fourth per the cycle PRD's resolved
sequencing (A → D → B → C). Translates `sub-prd.md` into a trackable
technical unit. The two artifacts are complementary — `sub-prd.md`
records product-level intent (user stories, scope, dependencies);
this file records the technical contract (acceptance criteria,
implementation approach, flags).

## Acceptance criteria

- [ ] `lua/colors/highlights/` exists as a directory of section
      modules. Each module is publicly `require`-able as
      `require("colors.highlights.<section>")` and exposes
      `M.highlights(c) → table` as a pure function — no `vim.*`
      calls, no side effects, no closure over module-private state
      beyond `local M = {}`. Verified by
      `grep -rn 'vim\.' lua/colors/highlights/` returning zero
      matches.
- [ ] `lua/colors/solarized.lua`'s `setup()` body no longer contains
      a single inline highlight table that enumerates the full set
      of groups. The literal table currently spanning lines ~111–455
      is gone; `setup()` requires the section modules, calls
      `highlights(c)` on each, merges, and applies via one
      `vim.api.nvim_set_hl` loop. Structural-intent AC; verified by
      reading the post-cycle `setup()` body against the pre-cycle
      `git show` output.
- [ ] The trailing manual `vim.api.nvim_set_hl` calls currently at
      lines ~462–491 of `solarized.lua` are folded into the
      appropriate section modules. After C, `setup()` has exactly
      one `for group, opts in pairs(merged) do
      vim.api.nvim_set_hl(0, group, opts) end` loop and zero
      additional `vim.api.nvim_set_hl` calls. Verified by
      `grep -n 'nvim_set_hl' lua/colors/solarized.lua` returning
      exactly one match.
- [ ] Each section module under `lua/colors/highlights/` has at
      least one passing unit test under
      `tests/colors/highlights/<section>_spec.lua` exercising
      `M.highlights(c)` as a pure function: pass a representative
      palette, assert the returned table contains the expected
      groups with the expected attributes for at least one entry
      per visual concern the section covers (e.g., a heading entry
      and a code entry for the markdown section).
- [ ] At least one composition-level spec exists at
      `tests/colors/solarized_composition_spec.lua` (or equivalent)
      exercising `solarized.setup()` end-to-end: stub
      `vim.api.nvim_set_hl` to record `(group, opts)`, call
      `setup("dark")`, assert a stable subset of the recorded calls
      includes one entry from each section and the
      template-literals / markdown override pairs in their
      expected final-write form. The subset asserted is the closure
      signal per cycle PRD constraint #6.
- [ ] Highlight output is preserved across the reshape. The set of
      groups recorded by the composition spec under `setup("dark")`
      and `setup("light")` matches — with respect to the asserted
      subset — the set of groups produced by the pre-cycle
      `setup()` on the same palette. No group is dropped, no
      attribute set is silently changed, no group is added.
- [ ] No edits to `lua/colors/os_theme.lua`, `lua/config/autocmds.lua`,
      `lua/plugins/lualine.lua`, `lua/config/commands.lua`,
      `lua/config/commands_registrar.lua`, `lua/utils/obsidian_cli/`,
      `lua/utils/wordcount.lua`, or `lua/utils/macos_codesign/`.
      Verified by `git diff` against the cycle base showing changes
      only under `lua/colors/solarized.lua`,
      `lua/colors/highlights/`, and `tests/colors/highlights/`
      (plus the composition spec).
- [ ] The palette tables in `solarized.lua` (`colors`, `dark_colors`,
      `light_colors`) are byte-for-byte unchanged from the pre-cycle
      base. The public surface (`M.setup`, `M.set_theme`, `M.toggle`,
      `M.subscribe`, `M.colors`, `M.dark_colors`, `M.light_colors`)
      retains its signatures and observable behavior. The
      `subscribe`/`emit` registry, the `os_theme.detect()` call site,
      the `vim.g.colors_name = nil` clear in `set_theme`/`toggle`,
      and the single `emit()` at the end of `setup()` are preserved.
- [ ] `./tests/run` exits 0 on the whole suite — including all cycle
      01, cycle 02, and cycle 03 (parents #22, #30, #32) specs.
- [ ] `PATH=/usr/bin:/bin ./tests/run` exits 0 (or equivalent — the
      suite passes with `obsidian`, `codesign`, and `defaults`
      absent from `$PATH`). Section-module specs do not depend on
      any external binary; the composition spec inherits parent
      #32's `vim.fn.has` stub pattern to keep `os_theme` from
      shelling out.
- [ ] No reaching into local functions or monkey-patching internals
      in any new spec. Carry-forward acceptance criterion from
      cycles 01–02 and parents #22, #30, #32, still binding.
      Section modules are tested through `M.highlights(c)`; the
      composition spec is tested through `solarized.setup()` with
      the same per-test `vim.api.nvim_set_hl` / `vim.cmd` /
      `vim.defer_fn` / `vim.fn.has` swaps the parents established.
- [ ] **Resolved-through-implementation decision recorded:** final
      section partition (names, count, membership of each section
      module). Decided in the first sub-issue and recorded in its
      AAR. The starting partition in `sub-prd.md` ("Scope" section)
      is the proposed default; deviations require a one-sentence
      reason in the AAR.
- [ ] **Resolved-through-implementation decision recorded:** merge
      order and override semantics — last-module-wins vs.
      no-shared-keys. Decided in the first sub-issue. Default
      expectation: last-module-wins for the
      template-literals/markdown contrast-override pairs, since
      that preserves current observable output without forcing a
      single augmented section module to absorb both sides of
      the override.
- [ ] **Resolved-through-implementation decision recorded:**
      composition-test depth (cycle PRD open question #5) —
      representative subset vs. full-table snapshot. Decided
      during the closing sub-issue. Default expectation: a
      representative-subset spec is sufficient unless
      implementation surfaces a composition-order regression the
      subset missed.
- [ ] **Resolved-through-implementation decision recorded:**
      whether C generates a flag for the cycle 03 PRD close's
      ADR-0004 evaluation (parent #32 open Q #4). The
      section-module pattern is structurally distinct from the
      "module-local seam with public setter" family of registrar
      (#22) + subscribe (#33) + os_theme (#35); whether it joins
      that ADR or warrants its own is a PRD-close call, not a
      C-internal one. Recorded in this parent's closing AAR.

## Implementation approach

### Section module shape (sketch — final shape decided in first sub-issue)

```lua
-- lua/colors/highlights/base.lua

local M = {}

function M.highlights(c)
  return {
    Normal       = { fg = c.fg0, bg = c.bg0 },
    NormalFloat  = { fg = c.fg0, bg = c.bg1 },
    NormalNC     = { fg = c.fg0, bg = c.bg0 },
    -- … the rest of the base/UI groups …
  }
end

return M
```

Pure: takes a palette table, returns a highlight-group map. No
`vim.*` calls, no `require` cycles, no closure over outer state.
Independently `require`-able and unit-testable.

### Composition root (sketch)

```lua
-- in lua/colors/solarized.lua

local SECTIONS = {
  "colors.highlights.base",
  "colors.highlights.syntax",
  "colors.highlights.lsp_diagnostic",
  "colors.highlights.template_literals",
  "colors.highlights.treesitter",
  "colors.highlights.markdown",
  "colors.highlights.treesitter_markdown",
  "colors.highlights.obsidian",
}

local function compose(c)
  local merged = {}
  for _, mod in ipairs(SECTIONS) do
    for group, opts in pairs(require(mod).highlights(c)) do
      merged[group] = opts  -- last-module-wins
    end
  end
  return merged
end

function M.setup(theme_override)
  local theme = theme_override or os_theme.detect()
  local c = theme == "dark" and dark_colors or light_colors

  vim.o.background = theme

  for group, opts in pairs(compose(c)) do
    vim.api.nvim_set_hl(0, group, opts)
  end

  vim.g.colors_name = "solarized"
  emit()
end
```

The `SECTIONS` list is the declarative spine — adding a new section
is a one-line addition to the list and one new file under
`lua/colors/highlights/`. Order is significant only where two
sections share a key (e.g., the template-literals/markdown override
pairs); the first sub-issue resolves whether this is acceptable
(last-module-wins, current default) or whether shared keys should
be forbidden by collapsing the override-pair into one section
module.

The `subscribe`/`emit` registry, the `os_theme.detect()` call site,
the `vim.o.background` assignment, the `vim.g.colors_name` write,
the `emit()` call, and `set_theme`/`toggle` are all preserved
unchanged. The reshape is contained to the body between resolving
`c` and writing `colors_name`.

### Sections (proposed starting partition — refined in first sub-issue)

| Section | Source lines (current) | Notable groups |
| --- | --- | --- |
| `base` | ~113–179 | Normal, Cursor, LineNr, StatusLine, TabLine, Windows, Search, Visual, Diff, Folding, SignColumn, ColorColumn, Pmenu, Messages |
| `syntax` | ~182–221 | Comment, Constant, Identifier, Statement, PreProc, Type, Special, Underlined, Bold, Italic |
| `lsp_diagnostic` | ~224–232 | LspReferenceText/Read/Write, DiagnosticError/Warn/Info/Hint |
| `template_literals` | ~235–245, ~462–469 | javaScriptStringT and `javaScriptStringT.html*` augmentation |
| `treesitter` | ~248–305, ~308–318 | `@comment`, `@function`, `@type`, `@text`, `@tag`, `@punctuation`, RainbowDelimiter*, `@macro`/`@define`/`@include`/`@preproc` |
| `markdown` | ~321–377, ~472–491 | `markdown*` legacy groups + Math, Task, Definition, contrast-override pairs |
| `treesitter_markdown` | ~380–434 | `@markdown.*` (heading, code, link, list, quote, table, footnote, frontmatter, escape) |
| `obsidian` | ~437–454, ~486–487 | `@markdown.wiki_link`, `@markdown.tag`, callouts, `markdownEmbeddedCode` |

Eight sections in the proposed default. The first sub-issue may
collapse adjacent sections (e.g., merge `lsp_diagnostic` into
`base` if the section is too small to justify its own module) or
split (e.g., separate rainbow delimiters from the general
treesitter section). The resulting count and naming is recorded in
the first sub-issue's AAR.

### Test pattern (per-section + composition)

**Per-section spec** — pure-function test:

1. `require` the section module.
2. Build a representative palette table (the test owns the
   palette; no need to load `solarized.lua`).
3. Call `M.highlights(c)`.
4. Assert specific entries in the returned table — at minimum one
   per visual concern the section covers.
5. Assert no side effects: the test does not need `pre_case` /
   `post_case` swaps because the section module touches no global
   state.

**Composition spec** — end-to-end through `setup()`:

1. In `pre_case`, swap `vim.api.nvim_set_hl` for a fake that
   records `(group, opts)` into a per-test table.
2. Stub `vim.cmd`, `vim.defer_fn`, and `vim.fn.has` per the parent
   #32 pattern, so `setup()` runs without shelling out and without
   touching the live editor.
3. Call `solarized.setup("dark")`.
4. Assert the recorded calls include the expected representative
   subset — one entry from each section, plus the
   template-literals / markdown override pairs in their final-write
   form (last-module-wins).
5. Repeat for `setup("light")` to cover both palettes.
6. In `post_case`, restore the originals via `mini.test.finally`.

The composition spec is the closure signal per cycle PRD constraint
#6. Whether to extend it from a representative subset to a
full-table snapshot is decided in the closing sub-issue
(open question #5 resolution).

### Override-pair handling

In the current `setup()`, the trailing manual `nvim_set_hl` calls
deliberately overwrite a subset of entries from the inlined table.
The known pairs:

- `javaScriptStringT` — set with `fg = c.yellow` in the table
  (line ~235), then overwritten with `fg = c.cyan, bg = c.bg1` in
  the manual block (line ~463). The latter wins.
- `markdownCodeBlock` — set with `fg = c.cyan, bg = c.bg1` in the
  table (line ~337) and again, identically, in the manual block
  (line ~490). No semantic override; redundant write.
- `markdownInlineCode` — same shape as `markdownCodeBlock`. Idem.

After C, these pairs need a deterministic resolution. Two options:

- **Last-module-wins** (default): `template_literals` is listed
  after the section that holds the original `javaScriptStringT`
  entry; the override naturally lands. The redundant
  `markdownCodeBlock` / `markdownInlineCode` writes collapse to
  one entry.
- **No-shared-keys**: collapse `template_literals` so it owns the
  final form of `javaScriptStringT` directly; the section the
  highlights table currently puts it in does not redefine it.
  Stronger invariant; requires the first sub-issue to disentangle
  the override-pair into one section module owning the final
  shape.

The first sub-issue picks one and records the rationale. Default
expectation: last-module-wins, since it preserves current
observable output without forcing the override-pair to collapse
during the tracer.

### Sequencing

Per the cycle 01 process spec — Stage 1 tracer → Stages 2–3
incremental TDD → Stage 4 deepen — this parent issue maps to a
rough plan of four-to-five sub-issues. Final sub-issue count and
grouping is decided per sub-issue, informed by prior AARs.

- **First sub-issue (#39, name TBD):** tracer slice. Build the
  `lua/colors/highlights/` directory, extract the smallest
  well-bounded section (proposed: `base` or `lsp_diagnostic`,
  whichever the first-sub-issue design pass picks for minimum
  blast radius). Reshape `setup()` into the composition root
  shape — the `SECTIONS` list, the `compose(c)` helper, the
  single apply loop. The remaining sections stay inlined inside
  `setup()` as a single intermediate-state table, fed into the
  same merge step as the extracted section's output. Add the
  first per-section spec and the first composition spec
  exercising the tracer's reshape. Resolve the section-partition
  decision and the merge-order decision in this sub-issue's AAR.

- **Subsequent sub-issues (#40+, name TBD):** extract remaining
  sections in batches. Rough groupings (final per-sub-issue,
  informed by prior AARs):

  - **Code-syntax batch:** `syntax`, `lsp_diagnostic`,
    `treesitter` (the non-markdown `@`-prefixed groups, plus
    rainbow delimiters). Per-section specs added alongside.
  - **Markdown batch:** `markdown`, `treesitter_markdown`,
    `obsidian`, `template_literals`. The override-pair handling
    lands in this batch.

  The batching may split or merge depending on what each AAR
  surfaces. The minimum is two extraction sub-issues after the
  tracer; the maximum is one per section if the AARs surface
  reasons to keep batches small.

- **Closing sub-issue (#XX, name TBD):** parent closure. Verify
  every section has been extracted and the inlined intermediate
  table is gone. Verify the trailing manual `nvim_set_hl` block
  has folded entirely into section modules. Resolve the
  composition-test-depth decision (cycle PRD open question #5).
  Record the ADR-0004 carry-forward note for the cycle 03 PRD
  close. Sibling `aar.md`. The next GitHub issue number belongs
  to the cycle 03 PRD close's AAR pass, not to a new parent
  issue (C is the last parent in the resolved sequencing).

Sub-issue numbering follows ADR-0002 — sequential GitHub issue
numbers, not cycle-local numbers.

### Constraints binding the implementation

1. The 18 user commands and the three `:Solarized*` commands keep
   their names, argument shapes, and observable behavior. No
   command is added, renamed, or removed in this parent issue.
2. The palette tables in `solarized.lua` (`colors`, `dark_colors`,
   `light_colors`) are unchanged. C does not adjust any color
   value or any palette-key name.
3. `M.setup`, `M.set_theme`, `M.toggle`, `M.subscribe`, `M.colors`,
   `M.dark_colors`, and `M.light_colors` retain their signatures
   and observable behavior. The `subscribe`/`emit` registry, the
   `os_theme.detect()` call site, and the `vim.g.colors_name`
   nil-clear in `set_theme`/`toggle` are preserved.
4. No edits to `lua/colors/os_theme.lua`,
   `lua/config/autocmds.lua`, `lua/plugins/lualine.lua`,
   `lua/config/commands.lua`, `lua/config/commands_registrar.lua`,
   `lua/utils/obsidian_cli/`, `lua/utils/wordcount.lua`, or
   `lua/utils/macos_codesign/`.
5. Section modules are pure. No `vim.*` call inside any module
   under `lua/colors/highlights/`. The single apply loop lives in
   `setup()`, the composition root.
6. Tests exercise public interfaces only. No reaching into locals,
   no monkey-patching internals beyond the per-test
   `vim.api.nvim_set_hl` / `vim.cmd` / `vim.defer_fn` /
   `vim.fn.has` swaps the composition spec inherits from parent
   #32's pattern.
7. The test suite runs to green with `defaults`, `obsidian`, and
   `codesign` absent from `$PATH`. The `os_theme` runner-seam
   from #35 ensures the composition spec never invokes the real
   `defaults` binary.
8. No new plugin dependencies. `mini.test` from cycle 01 remains
   the only test tooling.
9. No `mini.test.new_child_neovim` for any C spec. Section modules
   are pure functions; the composition spec is testable by
   stubbing `vim.api.nvim_set_hl`. A live editor session is not a
   closure requirement for C.

## Dependencies

- **Cycle 01 closure** — `mini.test` harness in place at
  `./tests/run`, `tests/init.lua` bootstrap with the `os.exit(0)`
  short-circuit preserved. Already closed.
- **Cycle 03 parent #22 (A) closure** — established the
  fake-the-API per-case swap pattern that C's composition spec
  reuses for `vim.api.nvim_set_hl`. Already closed.
- **Cycle 03 parent #30 (D) closure** — proved the discipline of
  not reaching into module locals beyond sanctioned setter seams.
  Already closed.
- **Cycle 03 parent #32 (B) closure** — established the post-`setup()`
  shape C inherits: `subscribe`/`emit`, `os_theme.detect()` call
  site, `vim.g.colors_name` nil-clear in `set_theme`/`toggle`. C
  does not touch those code paths; it reshapes only the highlights
  composed inside `setup()`. Already closed.
- **ADR-0001** — `mini.test` as the test runner.
- **ADR-0002** — folder slug `38-highlight-decomposition` tracks
  GitHub issue #38; sub-issues take sequential GitHub numbers.
- **ADR-0003** — does not bind C. Section modules are pure (no
  shell, no `vim.*` calls), so the four-layer subpackage shape is
  not applicable. Recorded explicitly so the absence of an
  ADR-0003 layout is not read as an oversight.
- **No dependency on any later parent.** C is the last parent in
  the resolved sequencing. The cycle 03 PRD close runs after C
  closes.

## Flags

*None yet. Sub-issue AARs surface flags as they appear.*
