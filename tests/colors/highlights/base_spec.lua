-- Per-section spec: base.highlights(c) is a pure function.
-- No pre_case / post_case swaps: the module touches no global state.

local T = MiniTest.new_set()

local function make_palette()
  return {
    fg0 = "#aaa", fg1 = "#bbb", fg2 = "#ccc",
    bg0 = "#000", bg1 = "#111", bg2 = "#222",
    yellow = "#ff0", orange = "#f80", red = "#f00",
    blue = "#00f", cyan = "#0ff", green = "#0f0",
    magenta = "#f0f", violet = "#80f",
  }
end

T["base.highlights returns Normal/NormalFloat/NormalNC with palette colors propagated"] = function()
  package.loaded["colors.highlights.base"] = nil
  local base = require("colors.highlights.base")
  local c = make_palette()

  local result = base.highlights(c)

  MiniTest.expect.equality(result.Normal.fg,      c.fg0)
  MiniTest.expect.equality(result.Normal.bg,      c.bg0)
  MiniTest.expect.equality(result.NormalFloat.fg, c.fg0)
  MiniTest.expect.equality(result.NormalFloat.bg, c.bg1)
  MiniTest.expect.equality(result.NormalNC.fg,    c.fg0)
  MiniTest.expect.equality(result.NormalNC.bg,    c.bg0)
end

T["base.highlights returns the cursor cluster"] = function()
  package.loaded["colors.highlights.base"] = nil
  local base = require("colors.highlights.base")
  local c = make_palette()

  local result = base.highlights(c)

  MiniTest.expect.equality(result.Cursor.fg,       c.bg0)
  MiniTest.expect.equality(result.Cursor.bg,       c.fg0)
  MiniTest.expect.equality(result.CursorLine.bg,   c.bg1)
  MiniTest.expect.equality(result.CursorColumn.bg, c.bg1)
  MiniTest.expect.equality(result.CursorLineNr.fg, c.fg2)
  MiniTest.expect.equality(result.CursorLineNr.bg, c.bg1)
end

T["base.highlights returns the statusline cluster"] = function()
  package.loaded["colors.highlights.base"] = nil
  local base = require("colors.highlights.base")
  local c = make_palette()

  local result = base.highlights(c)

  MiniTest.expect.equality(result.StatusLine.fg,       c.fg1)
  MiniTest.expect.equality(result.StatusLine.bg,       c.bg1)
  MiniTest.expect.equality(result.StatusLineNC.fg,     c.fg2)
  MiniTest.expect.equality(result.StatusLineNC.bg,     c.bg1)
  MiniTest.expect.equality(result.StatusLineTerm.fg,   c.fg1)
  MiniTest.expect.equality(result.StatusLineTerm.bg,   c.bg1)
  MiniTest.expect.equality(result.StatusLineTermNC.fg, c.fg2)
  MiniTest.expect.equality(result.StatusLineTermNC.bg, c.bg1)
end

T["base.highlights returns the messages cluster"] = function()
  package.loaded["colors.highlights.base"] = nil
  local base = require("colors.highlights.base")
  local c = make_palette()

  local result = base.highlights(c)

  MiniTest.expect.equality(result.ErrorMsg.fg,   c.red)
  MiniTest.expect.equality(result.WarningMsg.fg, c.yellow)
  MiniTest.expect.equality(result.ModeMsg.fg,    c.fg0)
  MiniTest.expect.equality(result.MoreMsg.fg,    c.blue)
  MiniTest.expect.equality(result.Question.fg,   c.cyan)
end

T["base.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.base"] = nil
  local base = require("colors.highlights.base")
  local c = make_palette()

  local r1 = base.highlights(c)
  local r2 = base.highlights(c)

  MiniTest.expect.equality(r1.Normal.fg, r2.Normal.fg)
  MiniTest.expect.equality(r1.StatusLine.bg, r2.StatusLine.bg)
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
