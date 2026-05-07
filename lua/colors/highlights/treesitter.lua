local M = {}

function M.highlights(c)
  return {
    ["@comment"]                  = { fg = c.fg2, italic = true },
    ["@string"]                   = { fg = c.cyan },
    ["@number"]                   = { fg = c.cyan },
    ["@boolean"]                  = { fg = c.cyan },

    ["@function"]                 = { fg = c.blue },
    ["@function.builtin"]         = { fg = c.blue },
    ["@function.macro"]           = { fg = c.blue },
    ["@parameter"]                = { fg = c.fg0 },
    ["@parameter.reference"]      = { fg = c.fg0 },
    ["@method"]                   = { fg = c.blue },
    ["@field"]                    = { fg = c.fg0 },
    ["@property"]                 = { fg = c.fg0 },
    ["@constructor"]              = { fg = c.yellow },

    ["@conditional"]              = { fg = c.green },
    ["@repeat"]                   = { fg = c.green },
    ["@label"]                    = { fg = c.green },
    ["@keyword"]                  = { fg = c.green },
    ["@operator"]                 = { fg = c.green },
    ["@keyword.function"]         = { fg = c.green },
    ["@keyword.operator"]         = { fg = c.green },
    ["@keyword.return"]           = { fg = c.green },
    ["@exception"]                = { fg = c.green },

    ["@type"]                     = { fg = c.yellow },
    ["@type.builtin"]             = { fg = c.yellow },
    ["@type.qualifier"]           = { fg = c.yellow },
    ["@type.definition"]          = { fg = c.yellow },
    ["@storageclass"]             = { fg = c.yellow },
    ["@attribute"]                = { fg = c.orange },

    ["@variable"]                 = { fg = c.fg0 },
    ["@variable.builtin"]         = { fg = c.orange },
    ["@constant"]                 = { fg = c.cyan },
    ["@constant.builtin"]         = { fg = c.cyan },
    ["@constant.macro"]           = { fg = c.cyan },
    ["@namespace"]                = { fg = c.fg0 },
    ["@symbol"]                   = { fg = c.magenta },

    ["@text"]                     = { fg = c.fg0 },
    ["@text.strong"]              = { bold = true },
    ["@text.emphasis"]            = { italic = true },
    ["@text.underline"]           = { underline = true },
    ["@text.title"]               = { fg = c.blue, bold = true },
    ["@text.literal"]             = { fg = c.cyan },
    ["@text.uri"]                 = { fg = c.blue, underline = true },
    ["@text.math"]                = { fg = c.magenta },
    ["@text.reference"]           = { fg = c.blue },
    ["@text.environment"]         = { fg = c.orange },
    ["@text.environment.name"]    = { fg = c.orange },
    ["@text.note"]                = { fg = c.cyan },
    ["@text.warning"]             = { fg = c.yellow },
    ["@text.danger"]              = { fg = c.red },

    ["@tag"]                      = { fg = c.magenta },
    ["@tag.delimiter"]            = { fg = c.fg2 },
    ["@tag.attribute"]            = { fg = c.orange },

    ["@punctuation"]              = { fg = c.fg2 },
    ["@punctuation.bracket"]      = { fg = c.fg2 },
    ["@punctuation.delimiter"]    = { fg = c.fg2 },
    ["@punctuation.special"]      = { fg = c.magenta },

    RainbowDelimiterRed           = { fg = c.red },
    RainbowDelimiterYellow        = { fg = c.yellow },
    RainbowDelimiterBlue          = { fg = c.blue },
    RainbowDelimiterOrange        = { fg = c.orange },
    RainbowDelimiterGreen         = { fg = c.green },
    RainbowDelimiterViolet        = { fg = c.violet },
    RainbowDelimiterCyan          = { fg = c.cyan },

    ["@macro"]                    = { fg = c.orange },
    ["@define"]                   = { fg = c.orange },
    ["@include"]                  = { fg = c.orange },
    ["@preproc"]                  = { fg = c.orange },
  }
end

return M
