local M = {}

function M.highlights(c)
  return {
    -- Wiki links — legacy and treesitter flavors
    markdownWikiLink             = { fg = c.violet, underline = true },
    markdownWikiLinkText         = { fg = c.violet, underline = true },
    ["@markdown.wiki_link"]      = { fg = c.violet, underline = true },
    ["@markdown.wiki_link_text"] = { fg = c.violet, underline = true },

    -- Tags / hashtags / mentions / highlights — legacy and treesitter flavors
    markdownTag                  = { fg = c.orange },
    markdownHashtag              = { fg = c.orange },
    markdownMention              = { fg = c.cyan },
    markdownHighlight            = { fg = c.yellow, bg = c.bg2 },
    ["@markdown.tag"]            = { fg = c.orange },
    ["@markdown.hashtag"]        = { fg = c.orange },
    ["@markdown.mention"]        = { fg = c.cyan },
    ["@markdown.highlight"]      = { fg = c.yellow, bg = c.bg2 },

    -- Callouts — legacy and treesitter flavors
    markdownCallout              = { fg = c.blue, bg = c.bg1 },
    markdownCalloutTitle         = { fg = c.blue, bold = true },
    ["@markdown.callout"]        = { fg = c.blue, bg = c.bg1 },
    ["@markdown.callout_title"]  = { fg = c.blue, bold = true },

    -- Embedded code (folded from trailing manual block)
    markdownEmbeddedCode         = { fg = c.cyan, bg = c.bg1 },
    markdownEmbeddedCodeDelimiter = { fg = c.fg2 },
  }
end

return M
