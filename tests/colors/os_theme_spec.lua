local _orig_fn_has = vim.fn.has
local _orig_o_bg   = vim.o.background

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      package.loaded["colors.os_theme"] = nil
      vim.fn.has = function(_) return 0 end
    end,
    post_case = function()
      vim.fn.has          = _orig_fn_has
      vim.o.background    = _orig_o_bg
      package.loaded["colors.os_theme"] = nil
    end,
  },
})

-- Case 1 — tracer: macOS branch delivers "dark" when runner outputs "Dark\n".
T["detect: macOS branch returns dark when runner outputs Dark"] = function()
  vim.fn.has = function(f) return f == "mac" and 1 or 0 end

  local os_theme = require("colors.os_theme")
  local calls = 0
  os_theme.set_runner(function(_cmd)
    calls = calls + 1
    return "Dark\n"
  end)

  local result = os_theme.detect()

  MiniTest.expect.equality(result, "dark")
  MiniTest.expect.equality(calls, 1)
end

-- Case 2 — macOS branch returns "light" when runner outputs empty string.
T["detect: macOS branch returns light when runner outputs empty"] = function()
  vim.fn.has = function(f) return f == "mac" and 1 or 0 end

  local os_theme = require("colors.os_theme")
  os_theme.set_runner(function(_cmd) return "\n" end)

  MiniTest.expect.equality(os_theme.detect(), "light")
end

-- Case 3 — macOS branch returns "light" when runner returns nil (popen failure).
T["detect: macOS branch returns light when runner returns nil"] = function()
  vim.fn.has = function(f) return f == "mac" and 1 or 0 end

  local os_theme = require("colors.os_theme")
  os_theme.set_runner(function(_cmd) return nil end)

  MiniTest.expect.equality(os_theme.detect(), "light")
end

-- Case 4 — Linux branch: capital-D "Dark" → "dark"; lowercase only → "light".
-- The parser uses :match("Dark") (case-sensitive), mirroring get_os_theme verbatim.
T["detect: Linux branch returns dark on capital-D Dark, light otherwise"] = function()
  vim.fn.has = function(f) return f == "unix" and 1 or 0 end

  local os_theme = require("colors.os_theme")

  os_theme.set_runner(function(_cmd) return "Dark\n" end)
  MiniTest.expect.equality(os_theme.detect(), "dark")

  -- Reset cache, swap to lowercase-only output.
  os_theme.refresh()
  os_theme.set_runner(function(_cmd) return "'adwaita-dark'\n" end)
  MiniTest.expect.equality(os_theme.detect(), "light")
end

-- Case 5 — fallback branch reads vim.o.background (no mac, no unix).
T["detect: fallback branch reads vim.o.background"] = function()
  vim.o.background = "dark"
  local os_theme   = require("colors.os_theme")
  MiniTest.expect.equality(os_theme.detect(), "dark")

  os_theme.refresh()
  vim.o.background = "light"
  MiniTest.expect.equality(os_theme.detect(), "light")
end

-- Case 6 — cache hit: runner invoked exactly once across two detect() calls.
T["detect: cache hit on second call, runner invoked once"] = function()
  vim.fn.has = function(f) return f == "mac" and 1 or 0 end

  local os_theme = require("colors.os_theme")
  local calls = 0
  os_theme.set_runner(function(_cmd)
    calls = calls + 1
    return "Dark\n"
  end)

  local first  = os_theme.detect()
  local second = os_theme.detect()

  MiniTest.expect.equality(calls, 1)
  MiniTest.expect.equality(first, "dark")
  MiniTest.expect.equality(second, "dark")
end

-- Case 7 — refresh() clears cache so next detect() re-runs the runner.
T["refresh: clears cache so next detect re-runs runner"] = function()
  vim.fn.has = function(f) return f == "mac" and 1 or 0 end

  local os_theme = require("colors.os_theme")
  local calls = 0
  os_theme.set_runner(function(_cmd)
    calls = calls + 1
    return "Dark\n"
  end)

  os_theme.detect()
  MiniTest.expect.equality(calls, 1)

  os_theme.refresh()

  os_theme.detect()
  MiniTest.expect.equality(calls, 2)
end

return T
