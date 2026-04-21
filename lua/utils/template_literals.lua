-- Manual template literal highlighting
-- This provides a fallback solution for HTML syntax highlighting in template literals

local M = {}

local function apply_template_literal_highlights()
  local solarized = require("colors.solarized")
  local c = (vim.o.background == "dark") and solarized.dark_colors or solarized.light_colors

  -- Keep these aligned with `colors.solarized` (same intent as the old Solarized-ish hexes).
  vim.api.nvim_set_hl(0, "javaScriptStringT", { fg = c.cyan, bg = c.bg1 })
  vim.api.nvim_set_hl(0, "javaScriptStringT_htmlTag", { fg = c.magenta })
  vim.api.nvim_set_hl(0, "javaScriptStringT_htmlTagName", { fg = c.blue })
  vim.api.nvim_set_hl(0, "javaScriptStringT_htmlEndTag", { fg = c.magenta })
  vim.api.nvim_set_hl(0, "javaScriptStringT_htmlArg", { fg = c.yellow })
  vim.api.nvim_set_hl(0, "javaScriptStringT_htmlString", { fg = c.cyan })
  vim.api.nvim_set_hl(0, "javaScriptStringT_cssProperty", { fg = c.yellow })
  vim.api.nvim_set_hl(0, "javaScriptStringT_cssBraces", { fg = c.magenta })
  vim.api.nvim_set_hl(0, "javaScriptStringT_cssSemicolon", { fg = c.green })
  vim.api.nvim_set_hl(0, "javaScriptStringT_cssValue", { fg = c.cyan })
end

function M.setup()
  -- Create custom syntax rules for template literals
  vim.cmd([[
    " Define syntax rules for HTML in template literals
    syntax match javaScriptStringT_htmlTag /<[^>]*>/ containedin=javaScriptStringT
    syntax match javaScriptStringT_htmlTagName /<\w\+/ containedin=javaScriptStringT_htmlTag
    syntax match javaScriptStringT_htmlEndTag /<\/\w\+>/ containedin=javaScriptStringT
    syntax match javaScriptStringT_htmlArg /\w\+=/ containedin=javaScriptStringT_htmlTag
    syntax match javaScriptStringT_htmlString /"[^"]*"/ containedin=javaScriptStringT_htmlTag
    syntax match javaScriptStringT_htmlString /'[^']*'/ containedin=javaScriptStringT_htmlTag
    
    " Link to existing HTML groups
    highlight link javaScriptStringT_htmlTag htmlTag
    highlight link javaScriptStringT_htmlTagName htmlTagName
    highlight link javaScriptStringT_htmlEndTag htmlEndTag
    highlight link javaScriptStringT_htmlArg htmlArg
    highlight link javaScriptStringT_htmlString htmlString
    
    " Define syntax rules for CSS in template literals
    syntax match javaScriptStringT_cssProperty /\w\+\s*:/ containedin=javaScriptStringT
    syntax match javaScriptStringT_cssBraces /[{}]/ containedin=javaScriptStringT
    syntax match javaScriptStringT_cssSemicolon /;/ containedin=javaScriptStringT
    syntax match javaScriptStringT_cssValue /:\s*[^;]*/ containedin=javaScriptStringT
    
    " Link to existing CSS groups
    highlight link javaScriptStringT_cssProperty cssProp
    highlight link javaScriptStringT_cssBraces cssBraces
    highlight link javaScriptStringT_cssSemicolon cssNoise
    highlight link javaScriptStringT_cssValue cssAttr
  ]])

  apply_template_literal_highlights()

  local group = vim.api.nvim_create_augroup("TemplateLiteralHighlights", { clear = true })
  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = group,
    pattern = "background",
    callback = function()
      vim.schedule(apply_template_literal_highlights)
    end,
  })
  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = group,
    pattern = "*",
    callback = function()
      vim.schedule(apply_template_literal_highlights)
    end,
  })
  
  -- Emmet configuration is handled in the plugins/init.lua file
  -- No need to duplicate the autocmd here as it's already configured in the plugin setup
end

-- Initialize the template literals highlighting
M.setup()

return M

