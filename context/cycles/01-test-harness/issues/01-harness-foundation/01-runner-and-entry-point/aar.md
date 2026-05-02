# AAR — Runner and entry point

1. **Did it go as planned?** No — the execution brief (parent issue prompt)
   superseded three interface decisions made in this sub-issue's plan.

2. **What changed from the sub-issue plan:**

   - **Interface choice reverted from B to A.** The sub-issue chose Alternative B
     (Makefile + `scripts/test.sh`). The execution brief specified `tests/run` with
     no Makefile. The Makefile criterion remains unchecked. `./tests/run` is the
     entry point.

   - **Bootstrap renamed and expanded.** Planned as `tests/minimal_init.lua`.
     Delivered as `tests/init.lua`. It does more than the plan described: it
     pre-collects spec files with an absolute `find_files` path (CWD-agnostic) and
     short-circuits with `os.exit(0)` when the collection is empty, because
     `mini.test` does not self-exit on zero cases.

   - **Tracer skipped; real spec delivered immediately.** The plan staged a trivial
     `1 == 1` tracer for this sub-issue, with sub-issue 2 replacing it. The
     execution brief directed a real spec (`tests/utils/wordcount_spec.lua`, 6
     cases over `utils.wordcount`'s public API) from the start.

   - **README pointer added early.** The plan explicitly deferred the README pointer
     to sub-issue 2. The execution brief included it here. Sub-issue 2 (if written)
     should not duplicate it.

   - **ADRs made:** None. ADR-0001 was pre-existing and remains accepted.

3. **Carry-forward:**

   - Flag written in parent: if a sub-issue 2 is planned, its original scope
     (replace tracer, add README pointer) is already done. The sub-issue 2
     description needs revision before activation.
   - Flag written in parent (pre-existing): `buf_line_range_wordcount` is untestable
     without a live buffer; address in a future refactor cycle.
   - The Makefile was not added. If `make test` muscle memory matters for this repo,
     a trivial two-line Makefile can be added in a future sub-issue or as a
     standalone commit — it is not blocking anything.
