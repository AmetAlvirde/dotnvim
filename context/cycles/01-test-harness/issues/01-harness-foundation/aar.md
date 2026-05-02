# Parent AAR — Harness foundation

1. **Did it go as planned?** Yes — every acceptance criterion in `issue.md`
   is satisfied. The parent collapsed into a single executed sub-issue
   (`01-runner-and-entry-point`) instead of the originally anticipated two.

2. **What changed from the parent issue plan:**

   - The plan staged a tracer spec in sub-issue 1 and a real
     `lua/utils/*` spec plus the README pointer in sub-issue 2. The
     execution brief for sub-issue 1 collapsed all of that into one pass:
     a real `tests/utils/wordcount_spec.lua` (6 cases over the public API
     of `utils.wordcount`) replaced the tracer, and the README "Testing"
     pointer landed early. Sub-issue 2 has no remaining scope and was not
     written.
   - Interface choice on the entry point reverted from the sub-issue
     plan's Alternative B (Makefile + `scripts/test.sh`) to Alternative A
     (`./tests/run`, no Makefile). The Makefile criterion is intentionally
     unchecked — `make test` is not the entry point for this repo.
   - Bootstrap was renamed from `tests/minimal_init.lua` to
     `tests/init.lua` and expanded beyond the plan: it pre-collects spec
     files via an absolute `find_files` path (CWD-agnostic) and
     short-circuits with `os.exit(0)` when the collection is empty,
     because `mini.test` does not self-exit on zero cases.

3. **ADRs made during this parent issue:** none. ADR-0001 (`mini.test as
   the test runner`) pre-existed, remains accepted, and is unchanged in
   `context/adr/INDEX.md`.

4. **New considerations or constraints surfaced:**

   - `utils.wordcount.buf_line_range_wordcount` cannot be exercised
     through its public interface without a live Neovim buffer
     (`nvim_buf_get_lines` requires a real buffer object). Untestable
     under the no-module-editing constraint of this cycle. A concrete
     example for the next refactor cycle of "module shape blocks the
     test, not the test framework."
   - `mini.test` does not self-exit when the collected case set is empty.
     Any future change to `tests/init.lua` must preserve the explicit
     `os.exit(0)` short-circuit, or the zero-spec acceptance criterion
     regresses silently.
   - Spec files must remain outside `lua/` because everything under
     `lua/` is `require`-able by the runtime. Re-derived during the
     decision and worth carrying forward as a stated constraint.

5. **Patterns across sub-issue AARs:** with only one sub-issue, this
   reduces to that AAR's central pattern — the execution brief for
   sub-issue 1 superseded three of the sub-issue's plan-level interface
   decisions (entry-point shape, bootstrap name and behavior, tracer vs.
   real spec). The brief's authority over the sub-issue plan was
   load-bearing here; a second sub-issue would have been pure overhead.

6. **Carry-forward — flags to write in the cycle, notes for the PRD AAR:**

   - All six PRD success metrics are satisfied; no cycle-level flag is
     needed against PRD acceptance.
   - For the PRD AAR: the cycle landed in one sub-issue rather than the
     anticipated multi-sub-issue split. Worth recording as a calibration
     note for sizing future cycles — "harness-shaped" cycles where the
     decisions are mostly resolved up front compress hard.
   - For the *next* cycle's pitch: `buf_line_range_wordcount` is a
     ready-made example of a module that must be reshaped before it can
     be tested. Reference it when motivating the refactor cycle.
   - The Makefile was deliberately not added. Any future sub-issue or
     pitch that assumes `make test` exists must account for this — the
     entry point is `./tests/run`. Adding a two-line Makefile later is
     non-blocking and can be a standalone commit.
