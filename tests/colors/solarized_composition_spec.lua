-- Composition spec: solarized.setup() end-to-end through a faked apply loop.
-- Inherits the per-test vim.api.nvim_set_hl / vim.cmd / vim.defer_fn / vim.fn.has
-- swap pattern established by parent #32's subscribe spec.

local _orig_set_hl   = vim.api.nvim_set_hl
local _orig_cmd      = vim.cmd
local _orig_defer_fn = vim.defer_fn
local _orig_fn_has   = vim.fn.has

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      _G.recorded_hls = {}

      -- Record every nvim_set_hl call (group → opts); last write wins per group,
      -- which is the current observable behavior for the trailing manual block.
      vim.api.nvim_set_hl = function(_, group, opts)
        _G.recorded_hls[group] = opts
      end

      vim.cmd        = function() end
      vim.defer_fn   = function(fn, _) fn() end
      -- Return 0 for vim.fn.has (defense-in-depth; bypassed by explicit theme_override).
      vim.fn.has     = function(_) return 0 end

      -- Pin background to "dark" to suppress Neovim's colorscheme-reapply path
      -- (carry-forward from #33's AAR).
      vim.o.background = "dark"

      package.loaded["colors.solarized"]                  = nil
      package.loaded["colors.highlights.lsp_diagnostic"]  = nil
      package.loaded["colors.os_theme"]                   = nil
    end,
    post_case = function()
      vim.api.nvim_set_hl = _orig_set_hl
      vim.cmd             = _orig_cmd
      vim.defer_fn        = _orig_defer_fn
      vim.fn.has          = _orig_fn_has

      _G.recorded_hls = nil

      package.loaded["colors.solarized"]                  = nil
      package.loaded["colors.highlights.lsp_diagnostic"]  = nil
      package.loaded["colors.os_theme"]                   = nil
    end,
  },
})

-- Tracer: dark palette — all seven lsp_diagnostic section groups are applied.
T["setup('dark') applies all seven lsp_diagnostic groups"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  -- dark_colors: red="#f23749", yellow="#ac8300", blue="#2b90d8", cyan="#259d94"
  -- bg2 = base01 = "#5b7279"
  MiniTest.expect.equality(_G.recorded_hls["LspReferenceText"].bg,  "#5b7279")
  MiniTest.expect.equality(_G.recorded_hls["LspReferenceRead"].bg,  "#5b7279")
  MiniTest.expect.equality(_G.recorded_hls["LspReferenceWrite"].bg, "#5b7279")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticError"].fg,   "#f23749")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticWarn"].fg,    "#ac8300")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticInfo"].fg,    "#2b90d8")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticHint"].fg,    "#259d94")
end

-- light palette — bg2 differs (base1 = "#8faaab"); accent colors are identical.
T["setup('light') applies all seven lsp_diagnostic groups"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("light")

  -- light_colors: bg2 = base1 = "#8faaab"; accents same as dark.
  MiniTest.expect.equality(_G.recorded_hls["LspReferenceText"].bg,  "#8faaab")
  MiniTest.expect.equality(_G.recorded_hls["LspReferenceRead"].bg,  "#8faaab")
  MiniTest.expect.equality(_G.recorded_hls["LspReferenceWrite"].bg, "#8faaab")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticError"].fg,   "#f23749")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticWarn"].fg,    "#ac8300")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticInfo"].fg,    "#2b90d8")
  MiniTest.expect.equality(_G.recorded_hls["DiagnosticHint"].fg,    "#259d94")
end

-- Probe: inlined rest table entries still reach the apply loop.
-- Normal and Comment remain in the inlined intermediate table this sub-issue.
T["setup('dark') applies a representative inlined entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  -- dark_colors: fg0="#98a8a8", bg0="#002d38", fg2="#657377"
  MiniTest.expect.equality(_G.recorded_hls["Normal"].fg, "#98a8a8")
  MiniTest.expect.equality(_G.recorded_hls["Normal"].bg, "#002d38")
  MiniTest.expect.equality(_G.recorded_hls["Comment"].fg, "#657377")
  MiniTest.expect.equality(_G.recorded_hls["Comment"].italic, true)
end

-- Trailing block: the imperative manual nvim_set_hl calls are preserved this sub-issue.
-- javaScriptStringT is overwritten by the trailing block: { fg = c.cyan, bg = c.bg1 }.
-- dark_colors: cyan="#259d94", bg1=base02="#093946".
T["setup('dark') still applies the trailing manual block"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  MiniTest.expect.equality(_G.recorded_hls["javaScriptStringT"].fg, "#259d94")
  MiniTest.expect.equality(_G.recorded_hls["javaScriptStringT"].bg, "#093946")
end

return T
