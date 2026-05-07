-- Per-section spec: treesitter_markdown.highlights(c) is a pure function.
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

T["treesitter_markdown.highlights returns the heading family"] = function()
  package.loaded["colors.highlights.treesitter_markdown"] = nil
  local tsmd = require("colors.highlights.treesitter_markdown")
  local c = make_palette()

  local result = tsmd.highlights(c)

  MiniTest.expect.equality(result["@markdown.heading"].fg,     c.blue)
  MiniTest.expect.equality(result["@markdown.heading"].bold,   true)
  MiniTest.expect.equality(result["@markdown.heading.1"].fg,   c.blue)
  MiniTest.expect.equality(result["@markdown.heading.1"].bold, true)
  MiniTest.expect.equality(result["@markdown.heading.2"].fg,   c.blue)
  MiniTest.expect.equality(result["@markdown.heading.3"].fg,   c.blue)
  MiniTest.expect.equality(result["@markdown.heading.4"].fg,   c.blue)
  MiniTest.expect.equality(result["@markdown.heading.5"].fg,   c.blue)
  MiniTest.expect.equality(result["@markdown.heading.6"].fg,   c.blue)
  MiniTest.expect.equality(result["@markdown.heading.marker"].fg, c.fg2)
end

T["treesitter_markdown.highlights returns the code family"] = function()
  package.loaded["colors.highlights.treesitter_markdown"] = nil
  local tsmd = require("colors.highlights.treesitter_markdown")
  local c = make_palette()

  local result = tsmd.highlights(c)

  MiniTest.expect.equality(result["@markdown.code"].fg,               c.cyan)
  MiniTest.expect.equality(result["@markdown.code"].bg,               c.bg1)
  MiniTest.expect.equality(result["@markdown.code_block"].fg,         c.cyan)
  MiniTest.expect.equality(result["@markdown.code_block"].bg,         c.bg1)
  MiniTest.expect.equality(result["@markdown.inline_code"].fg,        c.cyan)
  MiniTest.expect.equality(result["@markdown.inline_code"].bg,        c.bg1)
  MiniTest.expect.equality(result["@markdown.code_fence_content"].fg, c.cyan)
  MiniTest.expect.equality(result["@markdown.code_fence_content"].bg, c.bg1)
  MiniTest.expect.equality(result["@markdown.code_fence"].fg,         c.fg2)
end

T["treesitter_markdown.highlights returns the link family"] = function()
  package.loaded["colors.highlights.treesitter_markdown"] = nil
  local tsmd = require("colors.highlights.treesitter_markdown")
  local c = make_palette()

  local result = tsmd.highlights(c)

  MiniTest.expect.equality(result["@markdown.link"].fg,              c.blue)
  MiniTest.expect.equality(result["@markdown.link"].underline,       true)
  MiniTest.expect.equality(result["@markdown.link_text"].fg,         c.blue)
  MiniTest.expect.equality(result["@markdown.link_url"].fg,          c.cyan)
  MiniTest.expect.equality(result["@markdown.link_url"].underline,   true)
  MiniTest.expect.equality(result["@markdown.link_label"].fg,        c.magenta)
  MiniTest.expect.equality(result["@markdown.link_destination"].fg,  c.cyan)
end

T["treesitter_markdown.highlights returns the list/quote/table family"] = function()
  package.loaded["colors.highlights.treesitter_markdown"] = nil
  local tsmd = require("colors.highlights.treesitter_markdown")
  local c = make_palette()

  local result = tsmd.highlights(c)

  MiniTest.expect.equality(result["@markdown.list"].fg,              c.green)
  MiniTest.expect.equality(result["@markdown.list_marker"].fg,       c.green)
  MiniTest.expect.equality(result["@markdown.quote"].fg,             c.fg2)
  MiniTest.expect.equality(result["@markdown.quote"].italic,         true)
  MiniTest.expect.equality(result["@markdown.block_quote"].fg,       c.fg2)
  MiniTest.expect.equality(result["@markdown.table"].fg,             c.fg0)
  MiniTest.expect.equality(result["@markdown.table_head"].fg,        c.blue)
  MiniTest.expect.equality(result["@markdown.table_head"].bold,      true)
  MiniTest.expect.equality(result["@markdown.table_delimiter"].fg,   c.fg2)
end

T["treesitter_markdown.highlights returns frontmatter and escape families"] = function()
  package.loaded["colors.highlights.treesitter_markdown"] = nil
  local tsmd = require("colors.highlights.treesitter_markdown")
  local c = make_palette()

  local result = tsmd.highlights(c)

  MiniTest.expect.equality(result["@markdown.frontmatter"].fg,           c.fg2)
  MiniTest.expect.equality(result["@markdown.frontmatter_delimiter"].fg, c.fg2)
  MiniTest.expect.equality(result["@markdown.escape"].fg,                c.magenta)
  MiniTest.expect.equality(result["@markdown.escape_sequence"].fg,       c.magenta)
end

T["treesitter_markdown.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.treesitter_markdown"] = nil
  local tsmd = require("colors.highlights.treesitter_markdown")
  local c = make_palette()

  local r1 = tsmd.highlights(c)
  local r2 = tsmd.highlights(c)

  MiniTest.expect.equality(r1["@markdown.heading"].fg,   r2["@markdown.heading"].fg)
  MiniTest.expect.equality(r1["@markdown.code"].fg,      r2["@markdown.code"].fg)
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
