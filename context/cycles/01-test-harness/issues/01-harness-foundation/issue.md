# Parent Issue — Harness foundation

## Acceptance criteria

- [ ] Running the test entry point on a tree with zero specs exits 0.
- [ ] Running it with one passing example spec exits 0.
- [ ] Running it with one deliberately failing spec exits non-zero (verified
      by temporarily breaking an assertion, then reverting).
- [ ] At least one example spec exercises a real `lua/utils/*` module
      through its public interface, with no reaching into local functions or
      monkey-patching internals.
- [ ] `README.md` (or a `tests/README.md` linked from it) contains a one-line
      pointer to the entry point.
- [ ] `mini.test` is added to `lua/plugins/` and loads cleanly on Neovim
      startup — verified by `nvim --headless +qa` exiting 0.
- [ ] ADR-0001 remains accepted in `context/adr/INDEX.md` at closure.
- [ ] No existing module under `lua/` is moved, renamed, or modified beyond
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

[Written by sub-issue closures. Reviewed before activating any sub-issue.]
