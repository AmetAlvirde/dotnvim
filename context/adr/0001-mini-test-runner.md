# mini.test as the test runner

_Made during: 01-test-harness_
_Scope: product_
_Status: accepted_

The repo adopts `mini.test` (from `echasnovski/mini.nvim`) as its test runner.
It runs under `nvim --headless` with the real `vim.*` API available, is
purpose-built for testing rather than a side feature of a utility plugin, and
supports child-Neovim isolation for tests that mutate editor global state.

## Considered Options

- **`plenary.test_harness`** — already a transitive dependency via
  `obsidian.nvim`, busted-flavored API. Rejected because plenary's primary
  purpose is utilities for other plugins, not testing infrastructure: sparse
  docs on the test harness, periodic API drift between releases, and a known
  weak spot around async behavior. Coupling the test suite to a tool that is
  not optimized for that role is a long-term maintenance liability that "it's
  already on disk" does not offset.
- **`busted`** — the Lua testing standard. Rejected because it requires a
  separate luarocks toolchain, and running it against `vim.*` either forfeits
  busted's strengths (when run under `nvim --headless`) or forces stubbing
  every editor surface (`autocmds`, highlight groups, user commands,
  `vim.fn.systemlist`) that this configuration actually exercises.
