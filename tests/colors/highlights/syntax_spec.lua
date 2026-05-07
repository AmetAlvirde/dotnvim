-- Per-section spec: syntax.highlights(c) is a pure function.
-- No pre_case / post_case swaps: the module touches no global state.

local T = MiniTest.new_set()

local function make_palette()
  return {
    fg0 = "#aaa", fg2 = "#ccc",
    bg0 = "#000", bg1 = "#111",
    yellow = "#ff0", orange = "#f80", red = "#f00",
    blue = "#00f", cyan = "#0ff", green = "#0f0",
    magenta = "#f0f",
  }
end

T["syntax.highlights returns Comment with italic = true"] = function()
  package.loaded["colors.highlights.syntax"] = nil
  local syntax = require("colors.highlights.syntax")
  local c = make_palette()

  local result = syntax.highlights(c)

  MiniTest.expect.equality(result.Comment.fg,     c.fg2)
  MiniTest.expect.equality(result.Comment.italic, true)
end

T["syntax.highlights returns the constant cluster mapped to c.cyan"] = function()
  package.loaded["colors.highlights.syntax"] = nil
  local syntax = require("colors.highlights.syntax")
  local c = make_palette()

  local result = syntax.highlights(c)

  for _, key in ipairs({ "Constant", "String", "Character", "Number", "Boolean", "Float" }) do
    MiniTest.expect.equality(result[key].fg, c.cyan)
  end
end

T["syntax.highlights returns the type cluster mapped to c.yellow"] = function()
  package.loaded["colors.highlights.syntax"] = nil
  local syntax = require("colors.highlights.syntax")
  local c = make_palette()

  local result = syntax.highlights(c)

  for _, key in ipairs({ "Type", "StorageClass", "Structure", "Typedef" }) do
    MiniTest.expect.equality(result[key].fg, c.yellow)
  end
end

T["syntax.highlights returns Underlined/Bold/Italic with their attributes"] = function()
  package.loaded["colors.highlights.syntax"] = nil
  local syntax = require("colors.highlights.syntax")
  local c = make_palette()

  local result = syntax.highlights(c)

  MiniTest.expect.equality(result.Underlined.underline, true)
  MiniTest.expect.equality(result.Bold.bold,            true)
  MiniTest.expect.equality(result.Italic.italic,        true)
end

T["syntax.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.syntax"] = nil
  local syntax = require("colors.highlights.syntax")
  local c = make_palette()

  local r1 = syntax.highlights(c)
  local r2 = syntax.highlights(c)

  MiniTest.expect.equality(r1.Comment.fg,  r2.Comment.fg)
  MiniTest.expect.equality(r1.Keyword.fg,  r2.Keyword.fg)
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
