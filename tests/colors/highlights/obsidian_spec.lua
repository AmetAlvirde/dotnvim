-- Per-section spec: obsidian.highlights(c) is a pure function.
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

T["obsidian.highlights returns wiki-link entries in both flavors"] = function()
  package.loaded["colors.highlights.obsidian"] = nil
  local obs = require("colors.highlights.obsidian")
  local c = make_palette()

  local result = obs.highlights(c)

  MiniTest.expect.equality(result.markdownWikiLink.fg,               c.violet)
  MiniTest.expect.equality(result.markdownWikiLink.underline,        true)
  MiniTest.expect.equality(result.markdownWikiLinkText.fg,           c.violet)
  MiniTest.expect.equality(result["@markdown.wiki_link"].fg,         c.violet)
  MiniTest.expect.equality(result["@markdown.wiki_link"].underline,  true)
  MiniTest.expect.equality(result["@markdown.wiki_link_text"].fg,    c.violet)
end

T["obsidian.highlights returns tag/hashtag/mention/highlight in both flavors"] = function()
  package.loaded["colors.highlights.obsidian"] = nil
  local obs = require("colors.highlights.obsidian")
  local c = make_palette()

  local result = obs.highlights(c)

  MiniTest.expect.equality(result.markdownTag.fg,              c.orange)
  MiniTest.expect.equality(result.markdownHashtag.fg,          c.orange)
  MiniTest.expect.equality(result.markdownMention.fg,          c.cyan)
  MiniTest.expect.equality(result.markdownHighlight.fg,        c.yellow)
  MiniTest.expect.equality(result.markdownHighlight.bg,        c.bg2)
  MiniTest.expect.equality(result["@markdown.tag"].fg,         c.orange)
  MiniTest.expect.equality(result["@markdown.hashtag"].fg,     c.orange)
  MiniTest.expect.equality(result["@markdown.mention"].fg,     c.cyan)
  MiniTest.expect.equality(result["@markdown.highlight"].fg,   c.yellow)
  MiniTest.expect.equality(result["@markdown.highlight"].bg,   c.bg2)
end

T["obsidian.highlights returns callout entries"] = function()
  package.loaded["colors.highlights.obsidian"] = nil
  local obs = require("colors.highlights.obsidian")
  local c = make_palette()

  local result = obs.highlights(c)

  MiniTest.expect.equality(result.markdownCallout.fg,               c.blue)
  MiniTest.expect.equality(result.markdownCallout.bg,               c.bg1)
  MiniTest.expect.equality(result.markdownCalloutTitle.fg,          c.blue)
  MiniTest.expect.equality(result.markdownCalloutTitle.bold,        true)
  MiniTest.expect.equality(result["@markdown.callout"].fg,          c.blue)
  MiniTest.expect.equality(result["@markdown.callout"].bg,          c.bg1)
  MiniTest.expect.equality(result["@markdown.callout_title"].fg,    c.blue)
  MiniTest.expect.equality(result["@markdown.callout_title"].bold,  true)
end

T["obsidian.highlights returns the embedded-code cluster folded from the trailing block"] = function()
  package.loaded["colors.highlights.obsidian"] = nil
  local obs = require("colors.highlights.obsidian")
  local c = make_palette()

  local result = obs.highlights(c)

  MiniTest.expect.equality(result.markdownEmbeddedCode.fg,           c.cyan)
  MiniTest.expect.equality(result.markdownEmbeddedCode.bg,           c.bg1)
  MiniTest.expect.equality(result.markdownEmbeddedCodeDelimiter.fg,  c.fg2)
end

T["obsidian.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.obsidian"] = nil
  local obs = require("colors.highlights.obsidian")
  local c = make_palette()

  local r1 = obs.highlights(c)
  local r2 = obs.highlights(c)

  MiniTest.expect.equality(r1.markdownWikiLink.fg,           r2.markdownWikiLink.fg)
  MiniTest.expect.equality(r1["@markdown.callout"].fg,       r2["@markdown.callout"].fg)
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
