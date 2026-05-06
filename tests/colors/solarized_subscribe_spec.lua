-- Stage-2 tracer: subscribe registers a fn and set_theme delivers the emit.

local _orig_set_hl    = vim.api.nvim_set_hl
local _orig_cmd       = vim.cmd
local _orig_defer_fn  = vim.defer_fn
local _orig_fn_has    = vim.fn.has

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Force a fresh module load so subscriber state doesn't leak between cases.
      package.loaded["colors.solarized"] = nil

      -- Stub Neovim API calls that solarized.setup() makes internally.
      vim.api.nvim_set_hl = function() end
      vim.cmd             = function() end
      -- Execute deferred callbacks synchronously so test assertions fire immediately
      -- without scheduling timer work that could outlive the case.
      vim.defer_fn        = function(fn, _) fn() end
      -- Route get_os_theme() to the fallback (vim.o.background) without shelling out.
      vim.fn.has          = function(_) return 0 end

      -- Pin background to "dark" before any colorscheme name is active.
      -- This prevents Neovim's colorscheme-reapply machinery from firing when
      -- set_theme("dark") is called: because background does not change, the
      -- colors/solarized.lua entry-point is never re-executed mid-test.
      vim.o.background = "dark"
    end,
    post_case = function()
      vim.api.nvim_set_hl = _orig_set_hl
      vim.cmd             = _orig_cmd
      vim.defer_fn        = _orig_defer_fn
      vim.fn.has          = _orig_fn_has
      package.loaded["colors.solarized"] = nil
    end,
  },
})

-- Stage-2 tracer pair: the seam exists and delivers the emit.

T["subscribe: registered fn is called once after set_theme"] = function()
  local solarized = require("colors.solarized")

  local call_count = 0
  solarized.subscribe(function() call_count = call_count + 1 end)

  -- pre_case sets background="dark"; set_theme("dark") keeps background unchanged
  -- so Neovim's colorscheme-reapply path is never triggered.
  solarized.set_theme("dark")

  MiniTest.expect.equality(call_count, 1)
end

-- Stage-3 incremental tests follow.

T["subscribe: setup emits exactly once per invocation across two calls"] = function()
  local solarized = require("colors.solarized")

  local count = 0
  solarized.subscribe(function() count = count + 1 end)

  -- Call setup() directly twice with no background change between calls.
  -- This proves the "exactly once per invocation" property without triggering
  -- Neovim's colorscheme-reapply path (which fires only on background changes
  -- while a colorscheme is active).
  solarized.setup()
  MiniTest.expect.equality(count, 1)

  solarized.setup()
  MiniTest.expect.equality(count, 2)
end

T["subscribe: unsubscribe removes the subscriber"] = function()
  local solarized = require("colors.solarized")

  local count = 0
  local unsub = solarized.subscribe(function() count = count + 1 end)

  -- Same theme both times avoids a background change that would re-apply the
  -- colorscheme and produce a spurious extra emit.
  solarized.set_theme("dark")
  MiniTest.expect.equality(count, 1)

  unsub()

  solarized.set_theme("dark")
  MiniTest.expect.equality(count, 1)
end

T["subscribe: double-unsubscribe is idempotent (no error)"] = function()
  local solarized = require("colors.solarized")

  local unsub = solarized.subscribe(function() end)

  unsub()
  -- Second call must not raise.
  local ok = pcall(unsub)
  MiniTest.expect.equality(ok, true)
end

T["subscribe: multiple subscribers all receive the emit"] = function()
  local solarized = require("colors.solarized")

  local a, b = 0, 0
  solarized.subscribe(function() a = a + 1 end)
  solarized.subscribe(function() b = b + 1 end)

  solarized.set_theme("dark")

  MiniTest.expect.equality(a, 1)
  MiniTest.expect.equality(b, 1)
end

T["subscribe: one erroring subscriber does not block subsequent ones"] = function()
  local solarized = require("colors.solarized")

  local reached = false
  solarized.subscribe(function() error("intentional subscriber error") end)
  solarized.subscribe(function() reached = true end)

  solarized.set_theme("dark")

  MiniTest.expect.equality(reached, true)
end

-- Case 7 — FLAG-32-A resolution: exactly one emit when background flips.
-- Without the fix, set_theme("light") while colors_name="solarized" and
-- background="dark" fires two setup() calls (colorscheme-reapply + explicit),
-- producing count=2. Alternative A (clear colors_name before setup) must
-- yield count=1.
T["set_theme: emits exactly once when background flips"] = function()
  -- pre_case pins vim.o.background = "dark"; set colors_name to simulate
  -- production state where the solarized colorscheme is already active.
  vim.g.colors_name = "solarized"

  local solarized = require("colors.solarized")

  local count = 0
  solarized.subscribe(function() count = count + 1 end)

  solarized.set_theme("light")

  MiniTest.expect.equality(count, 1)
  -- setup() re-asserts colors_name at its end; confirm it is back.
  MiniTest.expect.equality(vim.g.colors_name, "solarized")
end

return T
