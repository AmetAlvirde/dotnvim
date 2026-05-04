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

T["command.orphans returns the static obsidian orphans string"] = function()
  MiniTest.expect.equality(command.orphans(), "obsidian orphans")
end

T["command.deadends returns the static obsidian deadends string"] = function()
  MiniTest.expect.equality(command.deadends(), "obsidian deadends")
end

T["command.tasks defaults to obsidian tasks todo verbose"] = function()
  MiniTest.expect.equality(command.tasks(), "obsidian tasks todo verbose")
end

T["command.tasks({}) matches the default"] = function()
  MiniTest.expect.equality(command.tasks({}), "obsidian tasks todo verbose")
end

T["command.tasks({ only_todo = true }) returns obsidian tasks todo verbose"] = function()
  MiniTest.expect.equality(command.tasks({ only_todo = true }), "obsidian tasks todo verbose")
end

T["command.tasks({ only_todo = false }) returns obsidian tasks verbose"] = function()
  MiniTest.expect.equality(command.tasks({ only_todo = false }), "obsidian tasks verbose")
end

T["command.unresolved returns the static obsidian unresolved verbose string"] = function()
  MiniTest.expect.equality(command.unresolved(), "obsidian unresolved verbose")
end

local function expect_backlinks_counts(cmd, rel)
  local expected = "obsidian backlinks path=" .. vim.fn.shellescape(rel) .. " counts format=json"
  MiniTest.expect.equality(cmd, expected)
end

T["command.backlinks_counts shell-escapes a plain vault-relative path"] = function()
  expect_backlinks_counts(command.backlinks_counts("notes/topic.md"), "notes/topic.md")
end

T["command.backlinks_counts shell-escapes a path with whitespace"] = function()
  expect_backlinks_counts(command.backlinks_counts("folder with spaces/note.md"), "folder with spaces/note.md")
end

T["command.backlinks_counts shell-escapes a path with single quotes"] = function()
  expect_backlinks_counts(command.backlinks_counts("it's complicated.md"), "it's complicated.md")
end

return T
