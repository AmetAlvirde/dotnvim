## Sub-PRD — macOS `codesign` workaround extraction (Candidate D)

> Translated to `issue.md`. This sub-PRD records the product-level intent --
> user stories and dependencies. Update `issue.md` for ongoing technical work.
> Update this file only if the underlying user stories themselves change.

Second parent issue of cycle `03-config-deepening`, per the resolved
sequencing in the cycle PRD's open question #1 (A → D → B → C).
Carries the cycle PRD's Candidate D goal — extracting the macOS
`codesign` re-signing workaround from `lua/config/autocmds.lua` into
a named, testable utility — and the slice of the cycle's cross-cutting
stories (4 and 5) that lands on this surface.

## Scope

Extract the macOS `codesign` re-signing workaround currently inlined in
`lua/config/autocmds.lua` into `lua/utils/macos_codesign/` following
the ADR-0003 four-layer subpackage pattern. The extracted utility exposes
one public function — `resign_lazy_plugins()` — that builds the `find`
+ `codesign` command string, runs it through a seamed shell adapter, and
emits the before/after notifications. The autocmd callback in
`autocmds.lua` becomes a one-line call to that function.

No parser or presenter layers are needed: the shell command's output is
discarded, and notifications are the utility's responsibility (the "UX"
of the operation), not the autocmd's.

The macOS `has("mac")` guard moves inside `resign_lazy_plugins()` so the
autocmd registration itself is unconditional — one fewer wrapping `if` in
`autocmds.lua`.

The workaround keeps firing on the same trigger events (`LazyInstall`,
`LazyUpdate`, `LazySync`, `LazyBuild`) with the same observable effect
(all `.so` files under the Lazy plugin directory are re-signed ad-hoc
after each plugin operation). No behavior change.

Out of scope for this parent issue:
- Async execution (the current `io.popen` is synchronous; switching to
  `vim.fn.jobstart` or a coroutine belongs to a future cycle if
  blocking proves a problem).
- Error reporting from `codesign` (current behavior discards exit code
  and output; improving error surfacing is a future cycle's call).
- Generalizing to a platform-detection utility. The `has("mac")` guard
  is self-contained.
- Editing any other autocmd in `autocmds.lua` beyond the codesign block.

## User stories

From the cycle PRD (story 4, sub-slice):

> As a maintainer auditing what in this configuration shells out to
> macOS, I want the `codesign` workaround in one named utility with a
> runner seam, so that I can disable, document, or test it without
> touching `autocmds.lua`.

From the cycle PRD (story 5, sub-slice):

> As a maintainer running the test suite headlessly, I want the
> `codesign` command builder to be exercised by at least one unit test
> against `./tests/run`, so that a regression in the command string
> cannot reach the configuration silently.

From the cycle PRD (story 6, sub-slice):

> As a maintainer of `autocmds.lua` at cycle close, I want the codesign
> autocmd to read as a one-line binding — `callback = function()
> require("utils.macos_codesign").resign_lazy_plugins() end` — so that
> the file's declarative spine is visible without reading the utility.

## Dependencies

- **ADR-0003** — mandates the four-layer subpackage layout (`command.lua`,
  `shell.lua`; parser and presenter layers omitted when not needed) and
  the setter-seam pattern on the shell adapter. Binding.
- **Cycle 03 parent #22 (A) closure** — established the fake-the-API
  test pattern that D will adapt for its shell-adapter seam. Closed.
- **`lua/config/autocmds.lua`** — the wiring file whose codesign block
  is extracted. Not restructured beyond the codesign block.
- **`lua/utils/macos_codesign/`** — new subpackage, created in this
  parent issue. Owned entirely by this parent.
- No dependency on parents B or C. D is sequenced before B because it
  is smaller and validates the ADR-0003 pattern on a new module type
  before B's larger reshape.
