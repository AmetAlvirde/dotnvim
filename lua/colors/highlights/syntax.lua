local M = {}

function M.highlights(c)
  return {
    Comment        = { fg = c.fg2, italic = true },

    Constant       = { fg = c.cyan },
    String         = { fg = c.cyan },
    Character      = { fg = c.cyan },
    Number         = { fg = c.cyan },
    Boolean        = { fg = c.cyan },
    Float          = { fg = c.cyan },

    Identifier     = { fg = c.blue },
    Function       = { fg = c.blue },

    Statement      = { fg = c.green },
    Conditional    = { fg = c.green },
    Repeat         = { fg = c.green },
    Label          = { fg = c.green },
    Operator       = { fg = c.green },
    Keyword        = { fg = c.green },
    Exception      = { fg = c.green },

    PreProc        = { fg = c.orange },
    Include        = { fg = c.orange },
    Define         = { fg = c.orange },
    Macro          = { fg = c.orange },
    PreCondit      = { fg = c.orange },

    Type           = { fg = c.yellow },
    StorageClass   = { fg = c.yellow },
    Structure      = { fg = c.yellow },
    Typedef        = { fg = c.yellow },

    Special        = { fg = c.magenta },
    SpecialChar    = { fg = c.magenta },
    Tag            = { fg = c.magenta },
    Delimiter      = { fg = c.magenta },
    SpecialComment = { fg = c.magenta },
    Debug          = { fg = c.magenta },

    Underlined     = { underline = true },
    Bold           = { bold = true },
    Italic         = { italic = true },
  }
end

return M
