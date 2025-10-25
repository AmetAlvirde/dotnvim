-- Manual template literal highlighting
-- This provides a fallback solution for HTML syntax highlighting in template literals

local M = {}

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
  ]])
  
  -- Add manual highlighting for template literals
  vim.cmd([[
    " Manual highlighting for template literals
    highlight javaScriptStringT ctermfg=cyan guifg=#2aa198
    highlight javaScriptStringT_htmlTag ctermfg=magenta guifg=#d33682
    highlight javaScriptStringT_htmlTagName ctermfg=blue guifg=#268bd2
    highlight javaScriptStringT_htmlEndTag ctermfg=magenta guifg=#d33682
    highlight javaScriptStringT_htmlArg ctermfg=yellow guifg=#b58900
    highlight javaScriptStringT_htmlString ctermfg=cyan guifg=#2aa198
  ]])
end

-- Initialize the template literals highlighting
M.setup()

return M
