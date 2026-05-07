local M = {}

function M.highlights(c)
  return {
    -- javaScriptStringT in its final form (Alternative A: single canonical definition;
    -- the stale { fg = c.yellow } from the inlined rest table is dropped entirely).
    javaScriptStringT              = { fg = c.cyan, bg = c.bg1 },

    -- HTML cluster (template-literal host language)
    htmlTag                        = { fg = c.magenta },
    htmlTagName                    = { fg = c.blue },
    htmlArg                        = { fg = c.orange },
    htmlString                     = { fg = c.cyan },
    htmlSpecialChar                = { fg = c.magenta },
    htmlEndTag                     = { fg = c.magenta },
    htmlLink                       = { fg = c.blue, underline = true },
    htmlBold                       = { bold = true },
    htmlItalic                     = { italic = true },
    htmlUnderline                  = { underline = true },

    -- javaScriptStringT.html* augmentation cluster (folded from trailing manual block)
    ["javaScriptStringT.htmlTag"]          = { fg = c.magenta, bold = true },
    ["javaScriptStringT.htmlTagName"]      = { fg = c.blue, bold = true },
    ["javaScriptStringT.htmlArg"]          = { fg = c.orange },
    ["javaScriptStringT.htmlString"]       = { fg = c.cyan },
    ["javaScriptStringT.htmlSpecialChar"]  = { fg = c.magenta },
    ["javaScriptStringT.htmlEndTag"]       = { fg = c.magenta, bold = true },
  }
end

return M
