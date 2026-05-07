-- Per-section spec: markdown.highlights(c) is a pure function.
-- No pre_case / post_case swaps: the module touches no global state.

local T = MiniTest.new_set()

local function make_palette()
  return {
    fg0 = "#98a8a8", fg2 = "#657377",
    bg0 = "#002d38", bg1 = "#093946", bg2 = "#5b7279",
    yellow = "#ac8300", orange = "#d56500", red = "#f23749",
    magenta = "#dd459d", violet = "#7d80d1",
    blue = "#2b90d8", cyan = "#259d94", green = "#819500",
  }
end

T["markdown.highlights returns the heading cluster"] = function()
  package.loaded["colors.highlights.markdown"] = nil
  local md = require("colors.highlights.markdown")
  local c = make_palette()

  local result = md.highlights(c)

  MiniTest.expect.equality(result.markdownH1.fg,   c.blue)
  MiniTest.expect.equality(result.markdownH1.bold, true)
  MiniTest.expect.equality(result.markdownH2.fg,   c.blue)
  MiniTest.expect.equality(result.markdownH2.bold, true)
  MiniTest.expect.equality(result.markdownH3.fg,   c.blue)
  MiniTest.expect.equality(result.markdownH4.fg,   c.blue)
  MiniTest.expect.equality(result.markdownH5.fg,   c.blue)
  MiniTest.expect.equality(result.markdownH6.fg,   c.blue)
  MiniTest.expect.equality(result.markdownHeadingDelimiter.fg, c.fg2)
  MiniTest.expect.equality(result.markdownHeadingRule.fg,      c.fg2)
end

T["markdown.highlights returns the code cluster, canonical definition"] = function()
  package.loaded["colors.highlights.markdown"] = nil
  local md = require("colors.highlights.markdown")
  local c = make_palette()

  local result = md.highlights(c)

  MiniTest.expect.equality(result.markdownCode.fg,            c.cyan)
  MiniTest.expect.equality(result.markdownCode.bg,            c.bg1)
  MiniTest.expect.equality(result.markdownCodeBlock.fg,       c.cyan)
  MiniTest.expect.equality(result.markdownCodeBlock.bg,       c.bg1)
  MiniTest.expect.equality(result.markdownInlineCode.fg,      c.cyan)
  MiniTest.expect.equality(result.markdownInlineCode.bg,      c.bg1)
  MiniTest.expect.equality(result.markdownCodeDelimiter.fg,   c.fg2)
end

T["markdown.highlights returns the link/url cluster"] = function()
  package.loaded["colors.highlights.markdown"] = nil
  local md = require("colors.highlights.markdown")
  local c = make_palette()

  local result = md.highlights(c)

  MiniTest.expect.equality(result.markdownLink.fg,                  c.blue)
  MiniTest.expect.equality(result.markdownLink.underline,           true)
  MiniTest.expect.equality(result.markdownLinkText.fg,              c.blue)
  MiniTest.expect.equality(result.markdownUrl.fg,                   c.cyan)
  MiniTest.expect.equality(result.markdownUrl.underline,            true)
  MiniTest.expect.equality(result.markdownUrlTitle.fg,              c.cyan)
  MiniTest.expect.equality(result.markdownAutomaticLink.fg,         c.blue)
  MiniTest.expect.equality(result.markdownAutomaticLink.underline,  true)
end

T["markdown.highlights returns the list/blockquote/table cluster"] = function()
  package.loaded["colors.highlights.markdown"] = nil
  local md = require("colors.highlights.markdown")
  local c = make_palette()

  local result = md.highlights(c)

  MiniTest.expect.equality(result.markdownListMarker.fg,         c.green)
  MiniTest.expect.equality(result.markdownOrderedListMarker.fg,  c.green)
  MiniTest.expect.equality(result.markdownUnorderedListMarker.fg, c.green)
  MiniTest.expect.equality(result.markdownBlockquote.fg,         c.fg2)
  MiniTest.expect.equality(result.markdownBlockquote.italic,     true)
  MiniTest.expect.equality(result.markdownTable.fg,              c.fg0)
  MiniTest.expect.equality(result.markdownTableHead.fg,          c.blue)
  MiniTest.expect.equality(result.markdownTableHead.bold,        true)
  MiniTest.expect.equality(result.markdownTableDelimiter.fg,     c.fg2)
end

T["markdown.highlights returns the math/task/definition cluster folded from the trailing block"] = function()
  package.loaded["colors.highlights.markdown"] = nil
  local md = require("colors.highlights.markdown")
  local c = make_palette()

  local result = md.highlights(c)

  MiniTest.expect.equality(result.markdownMath.fg,              c.magenta)
  MiniTest.expect.equality(result.markdownMath.bg,              c.bg1)
  MiniTest.expect.equality(result.markdownMathBlock.fg,         c.magenta)
  MiniTest.expect.equality(result.markdownMathBlock.bg,         c.bg1)
  MiniTest.expect.equality(result.markdownMathDelimiter.fg,     c.fg2)
  MiniTest.expect.equality(result.markdownMathBlockDelimiter.fg, c.fg2)
  MiniTest.expect.equality(result.markdownTaskChecked.fg,       c.green)
  MiniTest.expect.equality(result.markdownTaskChecked.bold,     true)
  MiniTest.expect.equality(result.markdownTaskUnchecked.fg,     c.fg2)
  MiniTest.expect.equality(result.markdownDefinitionTerm.fg,    c.blue)
  MiniTest.expect.equality(result.markdownDefinitionTerm.bold,  true)
  MiniTest.expect.equality(result.markdownDefinition.fg,        c.fg0)
end

T["markdown.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.markdown"] = nil
  local md = require("colors.highlights.markdown")
  local c = make_palette()

  local r1 = md.highlights(c)
  local r2 = md.highlights(c)

  MiniTest.expect.equality(r1.markdownH1.fg,        r2.markdownH1.fg)
  MiniTest.expect.equality(r1.markdownCodeBlock.fg, r2.markdownCodeBlock.fg)
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
