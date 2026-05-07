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
      -- which is the current observable behavior for the single apply loop.
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

      package.loaded["colors.solarized"]                       = nil
      package.loaded["colors.highlights.lsp_diagnostic"]       = nil
      package.loaded["colors.highlights.base"]                  = nil
      package.loaded["colors.highlights.syntax"]                = nil
      package.loaded["colors.highlights.treesitter"]            = nil
      package.loaded["colors.highlights.markdown"]              = nil
      package.loaded["colors.highlights.treesitter_markdown"]   = nil
      package.loaded["colors.highlights.obsidian"]              = nil
      package.loaded["colors.highlights.template_literals"]     = nil
      package.loaded["colors.os_theme"]                        = nil
    end,
    post_case = function()
      vim.api.nvim_set_hl = _orig_set_hl
      vim.cmd             = _orig_cmd
      vim.defer_fn        = _orig_defer_fn
      vim.fn.has          = _orig_fn_has

      _G.recorded_hls = nil

      package.loaded["colors.solarized"]                       = nil
      package.loaded["colors.highlights.lsp_diagnostic"]       = nil
      package.loaded["colors.highlights.base"]                  = nil
      package.loaded["colors.highlights.syntax"]                = nil
      package.loaded["colors.highlights.treesitter"]            = nil
      package.loaded["colors.highlights.markdown"]              = nil
      package.loaded["colors.highlights.treesitter_markdown"]   = nil
      package.loaded["colors.highlights.obsidian"]              = nil
      package.loaded["colors.highlights.template_literals"]     = nil
      package.loaded["colors.os_theme"]                        = nil
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

-- markdown section: markdownH1 is now owned by the markdown section module.
-- Replaces the former "inlined rest" probe (markdownH1 has migrated out of rest).
T["setup('dark') applies a markdown section entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  -- dark_colors: blue="#2b90d8"
  MiniTest.expect.equality(_G.recorded_hls["markdownH1"].fg,   "#2b90d8")
  MiniTest.expect.equality(_G.recorded_hls["markdownH1"].bold, true)
end

-- template_literals section: javaScriptStringT is now owned by template_literals
-- in its canonical final form (cyan/bg1). Replaces the former "trailing manual
-- block" probe; the fold preserved the value, not the trailing-block phase.
T["setup('dark') applies the template_literals canonical form for javaScriptStringT"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  -- dark_colors: cyan="#259d94", bg1=base02="#093946"
  MiniTest.expect.equality(_G.recorded_hls["javaScriptStringT"].fg, "#259d94")
  MiniTest.expect.equality(_G.recorded_hls["javaScriptStringT"].bg, "#093946")
end

-- base section: StatusLine uses fg1 (base1="#8faaab") and bg1 (base02="#093946") in dark.
T["setup('dark') applies a representative base entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  MiniTest.expect.equality(_G.recorded_hls["StatusLine"].fg, "#8faaab")
  MiniTest.expect.equality(_G.recorded_hls["StatusLine"].bg, "#093946")
end

-- syntax section: Comment uses fg2 (base00="#657377") in dark, italic=true.
T["setup('dark') applies a representative syntax entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  MiniTest.expect.equality(_G.recorded_hls["Comment"].fg,     "#657377")
  MiniTest.expect.equality(_G.recorded_hls["Comment"].italic, true)
end

-- treesitter section: @function uses blue="#2b90d8"; @text.strong is bold.
T["setup('dark') applies a representative treesitter entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  MiniTest.expect.equality(_G.recorded_hls["@function"].fg,       "#2b90d8")
  MiniTest.expect.equality(_G.recorded_hls["@text.strong"].bold,  true)
end

-- treesitter_markdown section: @markdown.heading owned by treesitter_markdown module.
T["setup('dark') applies a representative treesitter_markdown entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  -- dark_colors: blue="#2b90d8"
  MiniTest.expect.equality(_G.recorded_hls["@markdown.heading"].fg,   "#2b90d8")
  MiniTest.expect.equality(_G.recorded_hls["@markdown.heading"].bold, true)
end

-- obsidian section: markdownWikiLink owned by obsidian module.
T["setup('dark') applies a representative obsidian entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  -- dark_colors: violet="#7d80d1"
  MiniTest.expect.equality(_G.recorded_hls["markdownWikiLink"].fg,        "#7d80d1")
  MiniTest.expect.equality(_G.recorded_hls["markdownWikiLink"].underline,  true)
end

-- template_literals section: htmlTag owned by template_literals module.
T["setup('dark') applies a representative template_literals entry"] = function()
  local solarized = require("colors.solarized")
  solarized.setup("dark")

  -- dark_colors: magenta="#dd459d"
  MiniTest.expect.equality(_G.recorded_hls["htmlTag"].fg, "#dd459d")
end

return T
