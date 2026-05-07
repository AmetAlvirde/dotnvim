# AAR — Sub-issue #40: Code-syntax batch (`base` + `syntax` + `treesitter`)

1. **Did it go as planned?** Yes — all three section modules extracted verbatim,
   `SECTIONS` extended to four entries, `rest` shrunk to the markdown/HTML/Obsidian
   block, per-section specs and composition-spec extensions all passed green on the
   first run (159 cases, 0 failures).

2. **What changed from the sub-issue plan:**

   - **Duplicate `@field` / `@property` entries in original `rest` table:** The source
     `rest` table had `["@field"]` and `["@property"]` defined twice (lines ~258–259
     and ~276–277 in the original, with identical values). Lua silently takes the last
     definition in a table literal. `treesitter.lua` was written with each key appearing
     exactly once (the deduplicated form), which is byte-identical in observable output
     to the original's last-definition-wins behavior. No behavior change; recorded here
     for the markdown-batch author.

   - **Section-partition refinement (resolved — Alternative A confirmed):**
     Three separate modules — `base`, `syntax`, `treesitter` — as proposed. No reason
     surfaced during implementation to merge any pair. `base` placed in this batch
     (not its own sub-issue) is confirmed correct; it has no override pairs and fits
     naturally alongside the other non-markdown, non-LSP sections.

   - No other deviations from the sub-issue plan.

3. **Carry-forward:**

   - **No flags needed in parent #38.** `SECTIONS` ordering, section module shape,
     composition root, and public surface are all consistent with the parent's
     acceptance criteria and implementation sketch. The parent issue's resolved
     sequencing (tracer → code-syntax batch → markdown batch → closure) proceeds as
     planned.

   - **Duplicate-key note for markdown-batch author (#41):** Audit the `@markdown.*`
     and `markdownCodeBlock`/`markdownInlineCode` entries for duplicate keys in the
     inlined `rest` before extracting. The `javaScriptStringT` override pair (set in
     `rest`, overwritten by the trailing manual block) is the known intentional
     duplicate; confirm each other apparent duplicate is intentional before extracting.

   - **Composition-spec inlined-rest probe updated:** The probe now asserts
     `markdownH1` (still inlined) rather than `Normal`/`Comment` (now in section
     modules). The markdown-batch author should update it again when `markdownH1`
     migrates.
