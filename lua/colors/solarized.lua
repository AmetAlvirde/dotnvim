-- Custom Solarized theme with automatic dark/light mode switching
-- Based on the provided color palette with OKLCH values

local os_theme = require("colors.os_theme")

local M = {}

local subscribers = {}

function M.subscribe(fn)
  table.insert(subscribers, fn)
  local removed = false
  return function()
    if removed then return end
    removed = true
    for i, sub in ipairs(subscribers) do
      if sub == fn then
        table.remove(subscribers, i)
        return
      end
    end
  end
end

local function emit()
  for _, sub in ipairs(subscribers) do
    pcall(sub)
  end
end

-- Color palette from the provided table
local colors = {
  -- Base colors
  base03 = "#002d38",  -- Dark bg
  base02 = "#093946",  -- Dark bg highlights  
  base01 = "#5b7279",  -- Dark fg secondary
  base00 = "#657377",  -- Light fg secondary
  base0  = "#98a8a8",  -- Light fg primary
  base1  = "#8faaab",  -- Dark fg primary
  base2  = "#f1e9d2",  -- Light bg highlights
  base3  = "#fbf7ef",  -- Light bg
  
  -- Accent colors
  yellow   = "#ac8300",
  orange   = "#d56500", 
  red      = "#f23749",
  magenta  = "#dd459d",
  violet   = "#7d80d1",
  blue     = "#2b90d8",
  cyan     = "#259d94",
  green    = "#819500",
}

M.colors = colors

-- Dark theme colors
local dark_colors = {
  bg0 = colors.base03,
  bg1 = colors.base02,
  bg2 = colors.base01,
  fg0 = colors.base0,
  fg1 = colors.base1,
  fg2 = colors.base00,
  fg3 = colors.base01,
  
  -- Accent colors
  yellow = colors.yellow,
  orange = colors.orange,
  red = colors.red,
  magenta = colors.magenta,
  violet = colors.violet,
  blue = colors.blue,
  cyan = colors.cyan,
  green = colors.green,
}

M.dark_colors = dark_colors

-- Light theme colors  
local light_colors = {
  bg0 = colors.base3,
  bg1 = colors.base2,
  bg2 = colors.base1,
  fg0 = colors.base00,
  fg1 = colors.base01,
  fg2 = colors.base02,
  fg3 = colors.base03,
  
  -- Accent colors (same as dark)
  yellow = colors.yellow,
  orange = colors.orange,
  red = colors.red,
  magenta = colors.magenta,
  violet = colors.violet,
  blue = colors.blue,
  cyan = colors.cyan,
  green = colors.green,
}

M.light_colors = light_colors

local SECTIONS = {
  "colors.highlights.lsp_diagnostic",
  "colors.highlights.base",
  "colors.highlights.syntax",
  "colors.highlights.treesitter",
  "colors.highlights.markdown",
  "colors.highlights.treesitter_markdown",
  "colors.highlights.obsidian",
  "colors.highlights.template_literals",
}

-- Function to apply colorscheme
function M.setup(theme_override)
  local theme = theme_override or os_theme.detect()
  local c = theme == "dark" and dark_colors or light_colors

  -- Set background
  vim.o.background = theme

  local merged = {}
  for _, mod in ipairs(SECTIONS) do
    for group, opts in pairs(require(mod).highlights(c)) do
      merged[group] = opts
    end
  end

  for group, opts in pairs(merged) do
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Set colorscheme name
  vim.g.colors_name = "solarized"
  emit()
end

-- Function to toggle theme
function M.toggle()
  local next = vim.o.background == "dark" and "light" or "dark"
  -- Clear colors_name before background change to suppress Neovim's
  -- colorscheme-reapply path (FLAG-32-A); setup() re-asserts it at its end.
  vim.g.colors_name = nil
  M.setup(next)
  vim.cmd("redraw!")
end

-- Function to set specific theme
function M.set_theme(theme)
  if theme == "dark" or theme == "light" then
    -- Clear colors_name before setup to suppress Neovim's colorscheme-reapply
    -- path when background direction changes (FLAG-32-A); setup() re-asserts it.
    vim.g.colors_name = nil
    M.setup(theme)
    vim.cmd("redraw!")
  end
end

return M
