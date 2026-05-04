# AAR — Sub-issue #26: Solarized void rows

1. **Did it go as planned?** [Yes] — `kind = "void"` is implemented in the registrar, three Solarized commands migrate through `register`, three new spec cases cover the void contract, and the parent `issue.md` records the void-return decision with rejections for B and C.

2. **What changed from the sub-issue plan:**

   - **Formatting (post-merge preference):** The three Solarized `register({...})` calls were reverted from single-line form to multiline table literals for readability, matching the rest of `commands.lua`. The agent had used one-liners mainly to satisfy a `wc -l` comparison in the written acceptance list; the maintainer clarified that line targets in that list are **descriptive / directional**, not binding — **goals over line count**, and landing above a stated line budget when readability or structure demands it is acceptable.
   - **`commands.lua` line count:** With multiline blocks, `wc -l lua/config/commands.lua` is **273** (pre–#26 baseline in git was **259**), so the sub-issue’s “strictly less than 259” checklist item is **not** met as written. Treat the <120 parent target and intermediate line notes as **aspirational**; do not block future work on a literal line budget if behavior and structure are right.
   - **Live smoke check** (the three `:Solarized*` commands in a real Neovim session) was **not** run in the agent session; it remains a **manual** closure item for whoever merges.

3. **Carry-forward — flags, divergence, notes for parent AAR:**

   - **Registrar diff to remember:** The `kind == "void"` branch lives in `lua/config/commands_registrar.lua` after `pcall(require)` and `args` resolution, before `(success, msg)` handling: call `mod[spec.fn](unpack(args))`, return, no notify on success. Load failure path is unchanged; void rows still get ERROR `vim.notify` when the module fails to load.
   - **Deliberate-failure verification (done):** Placing the void branch *above* `pcall(require)` made the “void still surfaces load failure” spec fail (nil call / no proper notify). Revert confirmed ordering is load → args → void.
   - **Subsequent migration sub-issues:** No new flags. `WordCount` / custom notify remains a future shape decision, as in the sub-issue’s out-of-scope list.
   - **Parent #22:** Void modelling is **Alternative A** (`spec.kind = "void"`); already written into `context/cycles/03-config-deepening/issues/22-commands-registrar/issue.md`.
   - **ADRs:** None added; the choice is parent-documented. ADR-0002 already names this folder slug.

**Closure checks:** `./tests/run` — 104 cases, 0 failures (last run with `nvim` on `PATH`). No edits to `lua/colors/solarized.lua`, `lua/utils/obsidian_cli/`, or `lua/utils/wordcount.lua`. Glossary: no new domain terms for this seam.
