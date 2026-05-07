local M = {}

function M.highlights(c)
  return {
    -- Headings
    markdownH1                     = { fg = c.blue, bold = true },
    markdownH2                     = { fg = c.blue, bold = true },
    markdownH3                     = { fg = c.blue, bold = true },
    markdownH4                     = { fg = c.blue, bold = true },
    markdownH5                     = { fg = c.blue, bold = true },
    markdownH6                     = { fg = c.blue, bold = true },
    markdownHeadingDelimiter       = { fg = c.fg2 },
    markdownHeadingRule            = { fg = c.fg2 },

    -- Emphasis
    markdownBold                   = { bold = true },
    markdownItalic                 = { italic = true },
    markdownBoldItalic             = { bold = true, italic = true },
    markdownBoldDelimiter          = { fg = c.fg2 },
    markdownItalicDelimiter        = { fg = c.fg2 },

    -- Code (canonical single definitions; trailing-block redundant writes collapsed)
    markdownCode                   = { fg = c.cyan, bg = c.bg1 },
    markdownCodeBlock              = { fg = c.cyan, bg = c.bg1 },
    markdownCodeDelimiter          = { fg = c.fg2 },
    markdownInlineCode             = { fg = c.cyan, bg = c.bg1 },

    -- Links
    markdownLink                   = { fg = c.blue, underline = true },
    markdownLinkText               = { fg = c.blue, underline = true },
    markdownLinkDelimiter          = { fg = c.fg2 },
    markdownUrl                    = { fg = c.cyan, underline = true },
    markdownUrlTitle               = { fg = c.cyan },
    markdownUrlTitleDelimiter      = { fg = c.fg2 },

    -- Lists
    markdownListMarker             = { fg = c.green },
    markdownOrderedListMarker      = { fg = c.green },
    markdownUnorderedListMarker    = { fg = c.green },
    markdownListMarkerUnchecked    = { fg = c.fg2 },
    markdownListMarkerChecked      = { fg = c.green },

    -- Blockquote
    markdownBlockquote             = { fg = c.fg2, italic = true },
    markdownBlockquoteDelimiter    = { fg = c.fg2 },

    -- Horizontal rule
    markdownHr                     = { fg = c.fg2 },
    markdownRule                   = { fg = c.fg2 },

    -- Tables
    markdownTable                  = { fg = c.fg0 },
    markdownTableHead              = { fg = c.blue, bold = true },
    markdownTableDelimiter         = { fg = c.fg2 },
    markdownTableRow               = { fg = c.fg0 },
    markdownTableCell              = { fg = c.fg0 },

    -- Strikethrough
    markdownStrikethrough          = { strikethrough = true },
    markdownStrikethroughDelimiter = { fg = c.fg2 },

    -- Footnotes
    markdownFootnote               = { fg = c.magenta },
    markdownFootnoteDefinition     = { fg = c.magenta },
    markdownFootnoteDelimiter      = { fg = c.fg2 },

    -- Automatic links
    markdownAutomaticLink          = { fg = c.blue, underline = true },
    markdownAutomaticLinkDelimiter = { fg = c.fg2 },

    -- Escape
    markdownEscape                 = { fg = c.magenta },
    markdownEscapeDelimiter        = { fg = c.magenta },

    -- Math (folded from trailing manual block)
    markdownMath                   = { fg = c.magenta, bg = c.bg1 },
    markdownMathDelimiter          = { fg = c.fg2 },
    markdownMathBlock              = { fg = c.magenta, bg = c.bg1 },
    markdownMathBlockDelimiter     = { fg = c.fg2 },

    -- Task lists (folded from trailing manual block)
    markdownTaskChecked            = { fg = c.green, bold = true },
    markdownTaskUnchecked          = { fg = c.fg2 },

    -- Definition lists (folded from trailing manual block)
    markdownDefinitionTerm         = { fg = c.blue, bold = true },
    markdownDefinition             = { fg = c.fg0 },
  }
end

return M
