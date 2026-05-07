local M = {}

function M.highlights(c)
  return {
    -- Heading family
    ["@markdown.heading"]          = { fg = c.blue, bold = true },
    ["@markdown.heading.1"]        = { fg = c.blue, bold = true },
    ["@markdown.heading.2"]        = { fg = c.blue, bold = true },
    ["@markdown.heading.3"]        = { fg = c.blue, bold = true },
    ["@markdown.heading.4"]        = { fg = c.blue, bold = true },
    ["@markdown.heading.5"]        = { fg = c.blue, bold = true },
    ["@markdown.heading.6"]        = { fg = c.blue, bold = true },
    ["@markdown.heading.marker"]   = { fg = c.fg2 },

    -- Emphasis family
    ["@markdown.strong"]           = { bold = true },
    ["@markdown.emphasis"]         = { italic = true },
    ["@markdown.strong_emphasis"]  = { bold = true, italic = true },

    -- Code family
    ["@markdown.code"]             = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.code_block"]       = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.inline_code"]      = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.code_fence_content"] = { fg = c.cyan, bg = c.bg1 },
    ["@markdown.code_fence"]       = { fg = c.fg2 },

    -- Link family
    ["@markdown.link"]             = { fg = c.blue, underline = true },
    ["@markdown.link_text"]        = { fg = c.blue, underline = true },
    ["@markdown.link_url"]         = { fg = c.cyan, underline = true },
    ["@markdown.link_label"]       = { fg = c.magenta },
    ["@markdown.link_destination"] = { fg = c.cyan },

    -- List family
    ["@markdown.list"]             = { fg = c.green },
    ["@markdown.list_marker"]      = { fg = c.green },
    ["@markdown.list_item"]        = { fg = c.fg0 },
    ["@markdown.ordered_list"]     = { fg = c.green },
    ["@markdown.unordered_list"]   = { fg = c.green },

    -- Quote family
    ["@markdown.quote"]            = { fg = c.fg2, italic = true },
    ["@markdown.block_quote"]      = { fg = c.fg2, italic = true },
    ["@markdown.block_quote_marker"] = { fg = c.fg2 },

    -- Rule family
    ["@markdown.thematic_break"]   = { fg = c.fg2 },
    ["@markdown.horizontal_rule"]  = { fg = c.fg2 },

    -- Table family
    ["@markdown.table"]            = { fg = c.fg0 },
    ["@markdown.table_head"]       = { fg = c.blue, bold = true },
    ["@markdown.table_row"]        = { fg = c.fg0 },
    ["@markdown.table_cell"]       = { fg = c.fg0 },
    ["@markdown.table_delimiter"]  = { fg = c.fg2 },

    -- Strikethrough
    ["@markdown.strikethrough"]    = { strikethrough = true },

    -- Footnote family
    ["@markdown.footnote"]         = { fg = c.magenta },
    ["@markdown.footnote_definition"] = { fg = c.magenta },
    ["@markdown.footnote_reference"]  = { fg = c.magenta },

    -- Frontmatter family
    ["@markdown.frontmatter"]          = { fg = c.fg2 },
    ["@markdown.frontmatter_delimiter"] = { fg = c.fg2 },

    -- Escape family
    ["@markdown.escape"]           = { fg = c.magenta },
    ["@markdown.escape_sequence"]  = { fg = c.magenta },
  }
end

return M
