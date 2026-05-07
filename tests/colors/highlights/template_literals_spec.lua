-- Per-section spec: template_literals.highlights(c) is a pure function.
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

T["template_literals.highlights returns javaScriptStringT in its final form"] = function()
  package.loaded["colors.highlights.template_literals"] = nil
  local tl = require("colors.highlights.template_literals")
  local c = make_palette()

  local result = tl.highlights(c)

  -- Regression guard: must be the cyan/bg1 final form, not the stale { fg = c.yellow }
  -- from the pre-#41 inlined rest table.
  MiniTest.expect.equality(result.javaScriptStringT.fg, c.cyan)
  MiniTest.expect.equality(result.javaScriptStringT.bg, c.bg1)
end

T["template_literals.highlights returns the html cluster"] = function()
  package.loaded["colors.highlights.template_literals"] = nil
  local tl = require("colors.highlights.template_literals")
  local c = make_palette()

  local result = tl.highlights(c)

  MiniTest.expect.equality(result.htmlTag.fg,          c.magenta)
  MiniTest.expect.equality(result.htmlTagName.fg,      c.blue)
  MiniTest.expect.equality(result.htmlArg.fg,          c.orange)
  MiniTest.expect.equality(result.htmlString.fg,       c.cyan)
  MiniTest.expect.equality(result.htmlSpecialChar.fg,  c.magenta)
  MiniTest.expect.equality(result.htmlEndTag.fg,       c.magenta)
  MiniTest.expect.equality(result.htmlLink.fg,         c.blue)
  MiniTest.expect.equality(result.htmlLink.underline,  true)
  MiniTest.expect.equality(result.htmlBold.bold,       true)
  MiniTest.expect.equality(result.htmlItalic.italic,   true)
  MiniTest.expect.equality(result.htmlUnderline.underline, true)
end

T["template_literals.highlights returns the javaScriptStringT.html* augmentation cluster"] = function()
  package.loaded["colors.highlights.template_literals"] = nil
  local tl = require("colors.highlights.template_literals")
  local c = make_palette()

  local result = tl.highlights(c)

  MiniTest.expect.equality(result["javaScriptStringT.htmlTag"].fg,          c.magenta)
  MiniTest.expect.equality(result["javaScriptStringT.htmlTag"].bold,        true)
  MiniTest.expect.equality(result["javaScriptStringT.htmlTagName"].fg,      c.blue)
  MiniTest.expect.equality(result["javaScriptStringT.htmlTagName"].bold,    true)
  MiniTest.expect.equality(result["javaScriptStringT.htmlArg"].fg,          c.orange)
  MiniTest.expect.equality(result["javaScriptStringT.htmlString"].fg,       c.cyan)
  MiniTest.expect.equality(result["javaScriptStringT.htmlSpecialChar"].fg,  c.magenta)
  MiniTest.expect.equality(result["javaScriptStringT.htmlEndTag"].fg,       c.magenta)
  MiniTest.expect.equality(result["javaScriptStringT.htmlEndTag"].bold,     true)
end

T["template_literals.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.template_literals"] = nil
  local tl = require("colors.highlights.template_literals")
  local c = make_palette()

  local r1 = tl.highlights(c)
  local r2 = tl.highlights(c)

  MiniTest.expect.equality(r1.javaScriptStringT.fg,           r2.javaScriptStringT.fg)
  MiniTest.expect.equality(r1["javaScriptStringT.htmlEndTag"].fg, r2["javaScriptStringT.htmlEndTag"].fg)
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
