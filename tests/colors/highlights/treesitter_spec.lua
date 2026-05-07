-- Per-section spec: treesitter.highlights(c) is a pure function.
-- No pre_case / post_case swaps: the module touches no global state.

local T = MiniTest.new_set()

local function make_palette()
  return {
    fg0 = "#aaa", fg2 = "#ccc",
    bg0 = "#000", bg1 = "#111", bg2 = "#222",
    yellow = "#ff0", orange = "#f80", red = "#f00",
    blue = "#00f", cyan = "#0ff", green = "#0f0",
    magenta = "#f0f", violet = "#80f",
  }
end

T["treesitter.highlights returns @function and @function.builtin with palette colors propagated"] = function()
  package.loaded["colors.highlights.treesitter"] = nil
  local ts = require("colors.highlights.treesitter")
  local c = make_palette()

  local result = ts.highlights(c)

  MiniTest.expect.equality(result["@function"].fg,         c.blue)
  MiniTest.expect.equality(result["@function.builtin"].fg, c.blue)
  MiniTest.expect.equality(result["@function.macro"].fg,   c.blue)
end

T["treesitter.highlights returns the @text cluster"] = function()
  package.loaded["colors.highlights.treesitter"] = nil
  local ts = require("colors.highlights.treesitter")
  local c = make_palette()

  local result = ts.highlights(c)

  MiniTest.expect.equality(result["@text"].fg,          c.fg0)
  MiniTest.expect.equality(result["@text.strong"].bold, true)
  MiniTest.expect.equality(result["@text.title"].fg,    c.blue)
  MiniTest.expect.equality(result["@text.title"].bold,  true)
  MiniTest.expect.equality(result["@text.literal"].fg,  c.cyan)
end

T["treesitter.highlights returns the @tag and @punctuation clusters"] = function()
  package.loaded["colors.highlights.treesitter"] = nil
  local ts = require("colors.highlights.treesitter")
  local c = make_palette()

  local result = ts.highlights(c)

  MiniTest.expect.equality(result["@tag"].fg,                    c.magenta)
  MiniTest.expect.equality(result["@tag.delimiter"].fg,          c.fg2)
  MiniTest.expect.no_equality(result["@punctuation"],            nil)
  MiniTest.expect.equality(result["@punctuation.bracket"].fg,    c.fg2)
  MiniTest.expect.equality(result["@punctuation.delimiter"].fg,  c.fg2)
  MiniTest.expect.equality(result["@punctuation.special"].fg,    c.magenta)
end

T["treesitter.highlights returns the rainbow-delimiter cluster"] = function()
  package.loaded["colors.highlights.treesitter"] = nil
  local ts = require("colors.highlights.treesitter")
  local c = make_palette()

  local result = ts.highlights(c)

  MiniTest.expect.equality(result.RainbowDelimiterRed.fg,    c.red)
  MiniTest.expect.equality(result.RainbowDelimiterYellow.fg, c.yellow)
  MiniTest.expect.equality(result.RainbowDelimiterBlue.fg,   c.blue)
  MiniTest.expect.equality(result.RainbowDelimiterOrange.fg, c.orange)
  MiniTest.expect.equality(result.RainbowDelimiterGreen.fg,  c.green)
  MiniTest.expect.equality(result.RainbowDelimiterViolet.fg, c.violet)
  MiniTest.expect.equality(result.RainbowDelimiterCyan.fg,   c.cyan)
end

T["treesitter.highlights returns the @macro/@define/@include/@preproc cluster mapped to c.orange"] = function()
  package.loaded["colors.highlights.treesitter"] = nil
  local ts = require("colors.highlights.treesitter")
  local c = make_palette()

  local result = ts.highlights(c)

  MiniTest.expect.equality(result["@macro"].fg,   c.orange)
  MiniTest.expect.equality(result["@define"].fg,  c.orange)
  MiniTest.expect.equality(result["@include"].fg, c.orange)
  MiniTest.expect.equality(result["@preproc"].fg, c.orange)
end

T["treesitter.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.treesitter"] = nil
  local ts = require("colors.highlights.treesitter")
  local c = make_palette()

  local r1 = ts.highlights(c)
  local r2 = ts.highlights(c)

  MiniTest.expect.equality(r1["@function"].fg,  r2["@function"].fg)
  MiniTest.expect.equality(r1["@comment"].fg,   r2["@comment"].fg)
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
