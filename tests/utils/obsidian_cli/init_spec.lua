local T = MiniTest.new_set()

local obsidian_cli

T["tracer: module loads through the directory"] = function()
  local ok, mod = pcall(require, "utils.obsidian_cli")
  MiniTest.expect.equality(ok, true)
  MiniTest.expect.equality(type(mod), "table")
  obsidian_cli = mod
end

T["tracer: all 14 M.* names are functions"] = function()
  local mod = require("utils.obsidian_cli")
  local expected = {
    "orphans_to_quickfix",
    "deadends_to_quickfix",
    "unresolved_to_quickfix",
    "search_context_to_quickfix",
    "history_list_current",
    "history_read_current",
    "diff_current_from",
    "outline_current",
    "backlinks_counts_to_quickfix",
    "wordcount_current",
    "bookmarks_list_verbose",
    "bookmark_add_current",
    "tasks_to_quickfix",
    "toggle_task_from_quickfix",
  }
  for _, name in ipairs(expected) do
    MiniTest.expect.equality(
      type(mod[name]),
      "function",
      string.format("expected M.%s to be a function, got %s", name, type(mod[name]))
    )
  end
end

T["smoke: shell.set_runner and shell.reset_runner exist and are callable"] = function()
  local sh = require("utils.obsidian_cli.shell")
  MiniTest.expect.equality(type(sh.set_runner), "function")
  MiniTest.expect.equality(type(sh.reset_runner), "function")
  sh.set_runner(function()
    return {}, nil
  end)
  sh.reset_runner()
end

return T
