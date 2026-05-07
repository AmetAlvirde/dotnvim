local M = {}

function M.highlights(c)
  return {
    Normal           = { fg = c.fg0, bg = c.bg0 },
    NormalFloat      = { fg = c.fg0, bg = c.bg1 },
    NormalNC         = { fg = c.fg0, bg = c.bg0 },

    Cursor           = { fg = c.bg0, bg = c.fg0 },
    CursorLine       = { bg = c.bg1 },
    CursorColumn     = { bg = c.bg1 },
    CursorLineNr     = { fg = c.fg2, bg = c.bg1 },

    LineNr           = { fg = c.fg2 },
    LineNrAbove      = { fg = c.fg2 },
    LineNrBelow      = { fg = c.fg2 },

    StatusLine       = { fg = c.fg1, bg = c.bg1 },
    StatusLineNC     = { fg = c.fg2, bg = c.bg1 },
    StatusLineTerm   = { fg = c.fg1, bg = c.bg1 },
    StatusLineTermNC = { fg = c.fg2, bg = c.bg1 },

    TabLine          = { fg = c.fg2, bg = c.bg1 },
    TabLineFill      = { bg = c.bg1 },
    TabLineSel       = { fg = c.fg0, bg = c.bg0 },

    WinSeparator     = { fg = c.fg2 },
    VertSplit        = { fg = c.fg2 },

    Search           = { fg = c.yellow, bg = c.bg2 },
    IncSearch        = { fg = c.orange, bg = c.bg2 },
    CurSearch        = { fg = c.orange, bg = c.bg2 },

    Visual           = { bg = c.bg2 },
    VisualNOS        = { bg = c.bg2 },

    DiffAdd          = { fg = c.green,  bg = c.bg1 },
    DiffChange       = { fg = c.yellow, bg = c.bg1 },
    DiffDelete       = { fg = c.red,    bg = c.bg1 },
    DiffText         = { fg = c.blue,   bg = c.bg1 },

    Folded           = { fg = c.fg2, bg = c.bg1 },
    FoldColumn       = { fg = c.fg2, bg = c.bg0 },

    SignColumn       = { fg = c.fg2, bg = c.bg0 },

    ColorColumn      = { bg = c.bg1 },

    Pmenu            = { fg = c.fg0, bg = c.bg1 },
    PmenuSel         = { fg = c.bg0, bg = c.fg0 },
    PmenuSbar        = { bg = c.bg1 },
    PmenuThumb       = { bg = c.fg2 },

    ErrorMsg         = { fg = c.red,    bg = c.bg0 },
    WarningMsg       = { fg = c.yellow, bg = c.bg0 },
    ModeMsg          = { fg = c.fg0,    bg = c.bg0 },
    MoreMsg          = { fg = c.blue,   bg = c.bg0 },
    Question         = { fg = c.cyan,   bg = c.bg0 },
  }
end

return M
