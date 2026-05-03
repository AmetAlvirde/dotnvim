local T = MiniTest.new_set()
local command = require("utils.obsidian_cli.command")

local function expect_search_context(cmd, query)
  local expected = "obsidian search:context query=" .. vim.fn.shellescape(query)
  MiniTest.expect.equality(cmd, expected)
end

T["command.search_context builds plain ASCII queries"] = function()
  expect_search_context(command.search_context("hello"), "hello")
end

T["command.search_context escapes spaces"] = function()
  expect_search_context(command.search_context("two words"), "two words")
end

T["command.search_context escapes single quotes"] = function()
  expect_search_context(command.search_context("it's"), "it's")
end

T["command.search_context neutralizes shell metacharacters"] = function()
  local q = "a; rm -rf b"
  expect_search_context(command.search_context(q), q)
end

T["command.search_context accepts empty string"] = function()
  expect_search_context(command.search_context(""), "")
end

return T
