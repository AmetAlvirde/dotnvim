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

  -- Intermediate inlined table (shrinks as sections are extracted):
  -- Remaining: HTML/template-literal block, markdown* legacy groups,
  -- @markdown.* groups, and Obsidian extensions (~120 entries).
  local rest = {
    -- HTML Template Literals
    javaScriptStringT = { fg = c.yellow },
    htmlTag = { fg = c.magenta },
    htmlTagName = { fg = c.blue },
    htmlArg = { fg = c.orange },
    htmlString = { fg = c.cyan },
    htmlSpecialChar = { fg = c.magenta },
    htmlEndTag = { fg = c.magenta },
    htmlLink = { fg = c.blue, underline = true },
    htmlBold = { bold = true },
    htmlItalic = { italic = true },
    htmlUnderline = { underline = true },
    
    -- Markdown syntax highlighting
    markdownH1 = { fg = c.blue, bold = true },
    markdownH2 = { fg = c.blue, bold = true },
    markdownH3 = { fg = c.blue, bold = true },
    markdownH4 = { fg = c.blue, bold = true },
    markdownH5 = { fg = c.blue, bold = true },
    markdownH6 = { fg = c.blue, bold = true },
    markdownHeadingDelimiter = { fg = c.fg2 },
    markdownHeadingRule = { fg = c.fg2 },
    
    markdownBold = { bold = true },
    markdownItalic = { italic = true },
    markdownBoldItalic = { bold = true, italic = true },
    markdownBoldDelimiter = { fg = c.fg2 },
    markdownItalicDelimiter = { fg = c.fg2 },
    
    markdownCode = { fg = c.cyan, bg = c.bg1 },
    markdownCodeBlock = { fg = c.cyan, bg = c.bg1 },
    markdownCodeDelimiter = { fg = c.fg2 },
    markdownInlineCode = { fg = c.cyan, bg = c.bg1 },
    
    markdownLink = { fg = c.blue, underline = true },
    markdownLinkText = { fg = c.blue, underline = true },
    markdownLinkDelimiter = { fg = c.fg2 },
    markdownUrl = { fg = c.cyan, underline = true },
    markdownUrlTitle = { fg = c.cyan },
    markdownUrlTitleDelimiter = { fg = c.fg2 },
    
    markdownListMarker = { fg = c.green },
    markdownOrderedListMarker = { fg = c.green },
    markdownUnorderedListMarker = { fg = c.green },
    markdownListMarkerUnchecked = { fg = c.fg2 },
    markdownListMarkerChecked = { fg = c.green },
    
    markdownBlockquote = { fg = c.fg2, italic = true },
    markdownBlockquoteDelimiter = { fg = c.fg2 },
    
    markdownHr = { fg = c.fg2 },
    markdownRule = { fg = c.fg2 },
    
    markdownTable = { fg = c.fg0 },
    markdownTableHead = { fg = c.blue, bold = true },
    markdownTableDelimiter = { fg = c.fg2 },
    markdownTableRow = { fg = c.fg0 },
    markdownTableCell = { fg = c.fg0 },
    
    markdownStrikethrough = { strikethrough = true },
    markdownStrikethroughDelimiter = { fg = c.fg2 },
    
    markdownFootnote = { fg = c.magenta },
    markdownFootnoteDefinition = { fg = c.magenta },
    markdownFootnoteDelimiter = { fg = c.fg2 },
    
    markdownAutomaticLink = { fg = c.blue, underline = true },
    markdownAutomaticLinkDelimiter = { fg = c.fg2 },
    
    markdownEscape = { fg = c.magenta },
    markdownEscapeDelimiter = { fg = c.magenta },
    
    -- Treesitter markdown groups
    ["@markdown.heading"] = { fg = c.blue, bold = true },
    ["@markdown.heading.1"] = { fg = c.blue, bold = true },
    ["@markdown.heading.2"] = { fg = c.blue, bold = true },
    ["@markdown.heading.3"] = { fg = c.blue, bold = true },
    ["@markdown.heading.4"] = { fg = c.blue, bold = true },
    ["@markdown.heading.5"] = { fg = c.blue, bold = true },
    ["@markdown.heading.6"] = { fg = c.blue, bold = true },
    ["@markdown.heading.marker"] = { fg = c.fg2 },
    
    ["@markdown.strong"] = { bold = true },
    ["@markdown.emphasis"] = { italic = true },
    ["@markdown.strong_emphasis"] = { bold = true, italic = true },
    
    ["@markdown.code"] = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.code_block"] = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.inline_code"] = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.code_fence_content"] = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.code_fence"] = { fg = c.fg2 },
    
    ["@markdown.link"] = { fg = c.blue, underline = true },
    ["@markdown.link_text"] = { fg = c.blue, underline = true },
    ["@markdown.link_url"] = { fg = c.cyan, underline = true },
    ["@markdown.link_label"] = { fg = c.magenta },
    ["@markdown.link_destination"] = { fg = c.cyan },
    
    ["@markdown.list"] = { fg = c.green },
    ["@markdown.list_marker"] = { fg = c.green },
    ["@markdown.list_item"] = { fg = c.fg0 },
    ["@markdown.ordered_list"] = { fg = c.green },
    ["@markdown.unordered_list"] = { fg = c.green },
    
    ["@markdown.quote"] = { fg = c.fg2, italic = true },
    ["@markdown.block_quote"] = { fg = c.fg2, italic = true },
    ["@markdown.block_quote_marker"] = { fg = c.fg2 },
    
    ["@markdown.thematic_break"] = { fg = c.fg2 },
    ["@markdown.horizontal_rule"] = { fg = c.fg2 },
    
    ["@markdown.table"] = { fg = c.fg0 },
    ["@markdown.table_head"] = { fg = c.blue, bold = true },
    ["@markdown.table_row"] = { fg = c.fg0 },
    ["@markdown.table_cell"] = { fg = c.fg0 },
    ["@markdown.table_delimiter"] = { fg = c.fg2 },
    
    ["@markdown.strikethrough"] = { strikethrough = true },
    
    ["@markdown.footnote"] = { fg = c.magenta },
    ["@markdown.footnote_definition"] = { fg = c.magenta },
    ["@markdown.footnote_reference"] = { fg = c.magenta },
    
    ["@markdown.frontmatter"] = { fg = c.fg2 },
    ["@markdown.frontmatter_delimiter"] = { fg = c.fg2 },
    
    ["@markdown.escape"] = { fg = c.magenta },
    ["@markdown.escape_sequence"] = { fg = c.magenta },
    
    -- Obsidian-specific markdown extensions
    ["@markdown.wiki_link"] = { fg = c.violet, underline = true },
    ["@markdown.wiki_link_text"] = { fg = c.violet, underline = true },
    ["@markdown.tag"] = { fg = c.orange },
    ["@markdown.hashtag"] = { fg = c.orange },
    ["@markdown.mention"] = { fg = c.cyan },
    ["@markdown.highlight"] = { fg = c.yellow, bg = c.bg2 },
    ["@markdown.callout"] = { fg = c.blue, bg = c.bg1 },
    ["@markdown.callout_title"] = { fg = c.blue, bold = true },
    
    -- Additional markdown elements
    markdownWikiLink = { fg = c.violet, underline = true },
    markdownWikiLinkText = { fg = c.violet, underline = true },
    markdownTag = { fg = c.orange },
    markdownHashtag = { fg = c.orange },
    markdownMention = { fg = c.cyan },
    markdownHighlight = { fg = c.yellow, bg = c.bg2 },
    markdownCallout = { fg = c.blue, bg = c.bg1 },
    markdownCalloutTitle = { fg = c.blue, bold = true },
  }
  for group, opts in pairs(rest) do
    merged[group] = opts
  end

  for group, opts in pairs(merged) do
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Additional manual highlighting for template literals
  vim.api.nvim_set_hl(0, "javaScriptStringT", { fg = c.cyan, bg = c.bg1 })
  vim.api.nvim_set_hl(0, "javaScriptStringT.htmlTag", { fg = c.magenta, bold = true })
  vim.api.nvim_set_hl(0, "javaScriptStringT.htmlTagName", { fg = c.blue, bold = true })
  vim.api.nvim_set_hl(0, "javaScriptStringT.htmlArg", { fg = c.orange })
  vim.api.nvim_set_hl(0, "javaScriptStringT.htmlString", { fg = c.cyan })
  vim.api.nvim_set_hl(0, "javaScriptStringT.htmlSpecialChar", { fg = c.magenta })
  vim.api.nvim_set_hl(0, "javaScriptStringT.htmlEndTag", { fg = c.magenta, bold = true })
  
  -- Additional markdown-specific highlighting
  vim.api.nvim_set_hl(0, "markdownMath", { fg = c.magenta, bg = c.bg1 })
  vim.api.nvim_set_hl(0, "markdownMathDelimiter", { fg = c.fg2 })
  vim.api.nvim_set_hl(0, "markdownMathBlock", { fg = c.magenta, bg = c.bg1 })
  vim.api.nvim_set_hl(0, "markdownMathBlockDelimiter", { fg = c.fg2 })
  
  -- Task list highlighting
  vim.api.nvim_set_hl(0, "markdownTaskChecked", { fg = c.green, bold = true })
  vim.api.nvim_set_hl(0, "markdownTaskUnchecked", { fg = c.fg2 })
  
  -- Definition lists
  vim.api.nvim_set_hl(0, "markdownDefinitionTerm", { fg = c.blue, bold = true })
  vim.api.nvim_set_hl(0, "markdownDefinition", { fg = c.fg0 })
  
  -- Additional Obsidian features
  vim.api.nvim_set_hl(0, "markdownEmbeddedCode", { fg = c.cyan, bg = c.bg1 })
  vim.api.nvim_set_hl(0, "markdownEmbeddedCodeDelimiter", { fg = c.fg2 })
  
  -- Ensure proper contrast for readability
  vim.api.nvim_set_hl(0, "markdownCodeBlock", { fg = c.cyan, bg = c.bg1 })
  vim.api.nvim_set_hl(0, "markdownInlineCode", { fg = c.cyan, bg = c.bg1 })
  
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
