# AAR — Sub-issue #41: Markdown batch (`markdown` + `treesitter_markdown` + `obsidian` + `template_literals`)

1. **Did it go as planned?** Yes — all four section modules extracted, SECTIONS extended to
   eight entries, `rest` table and trailing manual block removed, per-section specs and
   composition-spec extensions all passed green on the first run (183 cases, 0 failures).

2. **What changed from the sub-issue plan:**

   - **Override-pair resolution confirmed as Alternative A (single definition per group).**
     `javaScriptStringT` is defined exactly once in `template_literals.lua` in its canonical
     `{ fg = c.cyan, bg = c.bg1 }` form. The stale `{ fg = c.yellow }` from the inlined `rest`
     table is dropped entirely. `markdownCodeBlock` and `markdownInlineCode` are each defined
     exactly once in `markdown.lua`; the redundant trailing-block writes are collapsed cleanly.
     No case arose during implementation where two modules needed to share a key.

   - **`setup()` body is now exactly the shape from parent #38's implementation sketch:**
     `vim.o.background = theme` → SECTIONS compose loop into `merged` → single apply loop →
     `vim.g.colors_name = "solarized"` → `emit()`. No `rest` table, no second loop, no
     trailing block.

   - **Composition spec re-purposed correctly:**
     - The "inlined rest probe" (`setup('dark') applies a representative inlined entry`)
       was renamed to `setup('dark') applies a markdown section entry`. Assertion values
       unchanged (`markdownH1.fg == "#2b90d8"`, `.bold == true`).
     - The "trailing manual block" case (`setup('dark') still applies the trailing manual
       block`) was renamed to `setup('dark') applies the template_literals canonical form
       for javaScriptStringT`. Assertion values unchanged (`fg == "#259d94"`, `bg == "#093946"`).
     - Four new representative-entry cases added: `markdown`, `treesitter_markdown`,
       `obsidian`, `template_literals`.
     - `pre_case` / `post_case` `package.loaded` clears extended with all four new module
       paths.

   - No duplicate keys found in the migrated entries. The #40 AAR carry-forward note about
     auditing `@markdown.*` duplicates was checked: no duplicate keys exist in the
     `treesitter_markdown` entries within the original `rest` table. The `javaScriptStringT`
     override pair (the only known intentional duplicate) was the sole case to resolve.

3. **Carry-forward:**

   - **No flags needed in parent #38.** All eight section modules extracted, single apply
     loop in `setup()`, trailing block gone, composition spec extended. Parent #38's AC
     for "no second imperative pass" is now true.

   - **Note for closing sub-issue (#42):** Post-#41 state to verify: eight entries in
     SECTIONS in the specified order, `rest` table absent, trailing `nvim_set_hl` block
     absent, exactly one `nvim_set_hl` call in `solarized.lua`, 183 test cases green.
     The composition-test-depth decision (cycle PRD open question #5) is deferred to #42
     as planned — the representative-subset spec was sufficient; no composition-order
     regression was missed by the subset.

   - **ADR-0004 carry-forward note (for PRD close):** The section-module pattern
     (`pure function → palette → highlight-group table`) is structurally distinct from
     the "module-local seam with public setter" family of registrar (#22), subscribe (#33),
     and os_theme (#35). Whether it warrants its own ADR entry or joins ADR-0004 is a
     PRD-close call, per parent #38's issue.md.
