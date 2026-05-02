# Parent Issue — Harness foundation

## Acceptance criteria

- [x] Running the test entry point on a tree with zero specs exits 0.
- [x] Running it with one passing example spec exits 0.
- [x] Running it with one deliberately failing spec exits non-zero (verified
      by temporarily breaking an assertion, then reverting).
- [x] At least one example spec exercises a real `lua/utils/*` module
      through its public interface, with no reaching into local functions or
      monkey-patching internals.
- [x] `README.md` (or a `tests/README.md` linked from it) contains a one-line
      pointer to the entry point.
- [x] `mini.test` is added to `lua/plugins/` and loads cleanly on Neovim
      startup — verified by `nvim --headless +qa` exiting 0.
- [x] ADR-0001 remains accepted in `context/adr/INDEX.md` at closure.
- [x] No existing module under `lua/` is moved, renamed, or modified beyond
      what is required to make it testable. Refactors are out of scope for
      this cycle.

## Implementation approach

- **Runner:** `mini.test` (per ADR-0001), loaded as a `lazy.nvim` plugin spec
  under `lua/plugins/`. Pull from `echasnovski/mini.nvim`. Whether to pull
  the full `mini.nvim` or pin only `mini.test` is decided in sub-issue 1.
- **Spec location:** `tests/<path>/<module>_spec.lua`, mirroring `lua/`.
- **Entry point:** a single executable shell script invoking `nvim
  --headless` with a `mini.test` collection. Whether a `Makefile` wraps it
  is decided in sub-issue 1.
- **Headless contract:** the entry point exits 0 on green, non-zero on red,
  and prints output proportional to outcome — quiet pass, loud fail.
- **No editing of existing modules.** The example spec exercises an
  unmodified `lua/utils/*` module. If a module cannot be tested through its
  public interface as-is, write a flag against the future refactor cycle —
  do not edit the module here.

## Dependencies

None. This is the first parent issue; nothing precedes it.

## Flags

- [ ] [sub-issue 1 → sub-issue 2, if written]

  Sub-issue 2 was scoped to replace a tracer spec and add the README pointer.
  Both are already done: `tests/utils/wordcount_spec.lua` is a real spec (6
  cases over `utils.wordcount`), and `README.md` already has the one-line
  Testing section. If a sub-issue 2 is activated, revise its description before
  starting — its original scope is complete.

  Files to review:
  - `tests/utils/wordcount_spec.lua`
  - `README.md`
  - `context/cycles/01-test-harness/issues/01-harness-foundation/01-runner-and-entry-point/aar.md`

- [ ] [sub-issue 1 → any future sub-issue touching the entry point]

  The Makefile was not created. The entry point is `./tests/run`, not
  `make test`. Any future sub-issue that references `make test` or assumes a
  Makefile exists must account for this. Adding a Makefile is low-effort if
  desired.

  Files to review:
  - `tests/run`
  - `context/cycles/01-test-harness/issues/01-harness-foundation/01-runner-and-entry-point/aar.md`

- `buf_line_range_wordcount` cannot be unit-tested through its public interface
  without a live Neovim buffer (`nvim_buf_get_lines` requires a real buffer object).
  Left untested per the no-module-editing constraint. Address in the next refactor cycle.
