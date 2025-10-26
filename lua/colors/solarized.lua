-- Custom Solarized theme with automatic dark/light mode switching
-- Based on the provided color palette with OKLCH values

local M = {}

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

-- Function to detect OS theme
local function get_os_theme()
  if vim.fn.has("mac") == 1 then
    -- On macOS, check the system appearance
    local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      return result:match("Dark") and "dark" or "light"
    end
  elseif vim.fn.has("unix") == 1 then
    -- On Linux, check gsettings or environment
    local handle = io.popen("gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      return result:match("Dark") and "dark" or "light"
    end
  end
  
  -- Fallback: check if background is set to dark
  return vim.o.background == "dark" and "dark" or "light"
end

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

-- Function to apply colorscheme
function M.setup()
  local theme = get_os_theme()
  local c = theme == "dark" and dark_colors or light_colors
  
  -- Set background
  vim.o.background = theme
  
  -- Define highlight groups
  local highlights = {
    -- Basic colors
    Normal = { fg = c.fg0, bg = c.bg0 },
    NormalFloat = { fg = c.fg0, bg = c.bg1 },
    NormalNC = { fg = c.fg0, bg = c.bg0 },
    
    -- Cursor
    Cursor = { fg = c.bg0, bg = c.fg0 },
    CursorLine = { bg = c.bg1 },
    CursorColumn = { bg = c.bg1 },
    CursorLineNr = { fg = c.fg2, bg = c.bg1 },
    
    -- Line numbers
    LineNr = { fg = c.fg2 },
    LineNrAbove = { fg = c.fg2 },
    LineNrBelow = { fg = c.fg2 },
    
    -- Status line
    StatusLine = { fg = c.fg1, bg = c.bg1 },
    StatusLineNC = { fg = c.fg2, bg = c.bg1 },
    StatusLineTerm = { fg = c.fg1, bg = c.bg1 },
    StatusLineTermNC = { fg = c.fg2, bg = c.bg1 },
    
    -- Tab line
    TabLine = { fg = c.fg2, bg = c.bg1 },
    TabLineFill = { bg = c.bg1 },
    TabLineSel = { fg = c.fg0, bg = c.bg0 },
    
    -- Windows
    WinSeparator = { fg = c.fg2 },
    VertSplit = { fg = c.fg2 },
    
    -- Search
    Search = { fg = c.yellow, bg = c.bg2 },
    IncSearch = { fg = c.orange, bg = c.bg2 },
    CurSearch = { fg = c.orange, bg = c.bg2 },
    
    -- Visual
    Visual = { bg = c.bg2 },
    VisualNOS = { bg = c.bg2 },
    
    -- Diff
    DiffAdd = { fg = c.green, bg = c.bg1 },
    DiffChange = { fg = c.yellow, bg = c.bg1 },
    DiffDelete = { fg = c.red, bg = c.bg1 },
    DiffText = { fg = c.blue, bg = c.bg1 },
    
    -- Folding
    Folded = { fg = c.fg2, bg = c.bg1 },
    FoldColumn = { fg = c.fg2, bg = c.bg0 },
    
    -- Sign column
    SignColumn = { fg = c.fg2, bg = c.bg0 },
    
    -- Color column (80-character line)
    ColorColumn = { bg = c.bg1 },
    
    -- Menu
    Pmenu = { fg = c.fg0, bg = c.bg1 },
    PmenuSel = { fg = c.bg0, bg = c.fg0 },
    PmenuSbar = { bg = c.bg1 },
    PmenuThumb = { bg = c.fg2 },
    
    -- Messages
    ErrorMsg = { fg = c.red, bg = c.bg0 },
    WarningMsg = { fg = c.yellow, bg = c.bg0 },
    ModeMsg = { fg = c.fg0, bg = c.bg0 },
    MoreMsg = { fg = c.blue, bg = c.bg0 },
    Question = { fg = c.cyan, bg = c.bg0 },
    
    -- Syntax highlighting
    Comment = { fg = c.fg2, italic = true },
    Constant = { fg = c.cyan },
    String = { fg = c.cyan },
    Character = { fg = c.cyan },
    Number = { fg = c.cyan },
    Boolean = { fg = c.cyan },
    Float = { fg = c.cyan },
    
    Identifier = { fg = c.blue },
    Function = { fg = c.blue },
    
    Statement = { fg = c.green },
    Conditional = { fg = c.green },
    Repeat = { fg = c.green },
    Label = { fg = c.green },
    Operator = { fg = c.green },
    Keyword = { fg = c.green },
    Exception = { fg = c.green },
    
    PreProc = { fg = c.orange },
    Include = { fg = c.orange },
    Define = { fg = c.orange },
    Macro = { fg = c.orange },
    PreCondit = { fg = c.orange },
    
    Type = { fg = c.yellow },
    StorageClass = { fg = c.yellow },
    Structure = { fg = c.yellow },
    Typedef = { fg = c.yellow },
    
    Special = { fg = c.magenta },
    SpecialChar = { fg = c.magenta },
    Tag = { fg = c.magenta },
    Delimiter = { fg = c.magenta },
    SpecialComment = { fg = c.magenta },
    Debug = { fg = c.magenta },
    
    Underlined = { underline = true },
    Bold = { bold = true },
    Italic = { italic = true },
    
    -- LSP
    LspReferenceText = { bg = c.bg2 },
    LspReferenceRead = { bg = c.bg2 },
    LspReferenceWrite = { bg = c.bg2 },
    
    -- Diagnostic
    DiagnosticError = { fg = c.red },
    DiagnosticWarn = { fg = c.yellow },
    DiagnosticInfo = { fg = c.blue },
    DiagnosticHint = { fg = c.cyan },

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
    
    -- Treesitter
    ["@comment"] = { fg = c.fg2, italic = true },
    ["@string"] = { fg = c.cyan },
    ["@number"] = { fg = c.cyan },
    ["@boolean"] = { fg = c.cyan },
    ["@function"] = { fg = c.blue },
    ["@function.builtin"] = { fg = c.blue },
    ["@function.macro"] = { fg = c.blue },
    ["@parameter"] = { fg = c.fg0 },
    ["@parameter.reference"] = { fg = c.fg0 },
    ["@method"] = { fg = c.blue },
    ["@field"] = { fg = c.fg0 },
    ["@property"] = { fg = c.fg0 },
    ["@constructor"] = { fg = c.yellow },
    ["@conditional"] = { fg = c.green },
    ["@repeat"] = { fg = c.green },
    ["@label"] = { fg = c.green },
    ["@keyword"] = { fg = c.green },
    ["@operator"] = { fg = c.green },
    ["@keyword.function"] = { fg = c.green },
    ["@keyword.operator"] = { fg = c.green },
    ["@keyword.return"] = { fg = c.green },
    ["@exception"] = { fg = c.green },
    ["@type"] = { fg = c.yellow },
    ["@type.builtin"] = { fg = c.yellow },
    ["@type.qualifier"] = { fg = c.yellow },
    ["@type.definition"] = { fg = c.yellow },
    ["@storageclass"] = { fg = c.yellow },
    ["@attribute"] = { fg = c.orange },
    ["@field"] = { fg = c.fg0 },
    ["@property"] = { fg = c.fg0 },
    ["@variable"] = { fg = c.fg0 },
    ["@variable.builtin"] = { fg = c.orange },
    ["@constant"] = { fg = c.cyan },
    ["@constant.builtin"] = { fg = c.cyan },
    ["@constant.macro"] = { fg = c.cyan },
    ["@namespace"] = { fg = c.fg0 },
    ["@symbol"] = { fg = c.magenta },
    ["@text"] = { fg = c.fg0 },
    ["@text.strong"] = { bold = true },
    ["@text.emphasis"] = { italic = true },
    ["@text.underline"] = { underline = true },
    ["@text.title"] = { fg = c.blue, bold = true },
    ["@text.literal"] = { fg = c.cyan },
    ["@text.uri"] = { fg = c.blue, underline = true },
    ["@text.math"] = { fg = c.magenta },
    ["@text.reference"] = { fg = c.blue },
    ["@text.environment"] = { fg = c.orange },
    ["@text.environment.name"] = { fg = c.orange },
    ["@text.note"] = { fg = c.cyan },
    ["@text.warning"] = { fg = c.yellow },
    ["@text.danger"] = { fg = c.red },
    ["@tag"] = { fg = c.magenta },
    ["@tag.delimiter"] = { fg = c.fg2 },
    ["@tag.attribute"] = { fg = c.orange },
    ["@punctuation"] = { fg = c.fg2 },
    ["@punctuation.bracket"] = { fg = c.fg2 },
    ["@punctuation.delimiter"] = { fg = c.fg2 },
    ["@punctuation.special"] = { fg = c.magenta },
    ["@macro"] = { fg = c.orange },
    ["@define"] = { fg = c.orange },
    ["@include"] = { fg = c.orange },
    ["@preproc"] = { fg = c.orange },
  }
  
  -- Apply highlights
  for group, opts in pairs(highlights) do
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
  
  -- Set colorscheme name
  vim.g.colors_name = "solarized"
end

-- Function to toggle theme
function M.toggle()
  if vim.o.background == "dark" then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
  M.setup()
end

-- Function to set specific theme
function M.set_theme(theme)
  if theme == "dark" or theme == "light" then
    vim.o.background = theme
    M.setup()
  end
end

return M
