local T = MiniTest.new_set()
local parsers = require("utils.obsidian_cli.parsers")

local function item(filename, lnum, text)
  return {
    filename = filename,
    lnum = lnum,
    col = 1,
    text = text,
  }
end

T["parsers.search_context parses path:line:text lines"] = function()
  local items = parsers.search_context({ "notes/foo.md:42: matched text" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1], item("notes/foo.md", 42, "matched text"))
end

T["parsers.search_context parses path:line text lines"] = function()
  local items = parsers.search_context({ "notes/bar.md:7  prefix rest" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1], item("notes/bar.md", 7, "prefix rest"))
end

T["parsers.search_context parses TSV-shaped lines"] = function()
  local line = "notes/baz.md\t13\trest of line"
  local items = parsers.search_context({ line })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1], item("notes/baz.md", 13, "rest of line"))
end

T["parsers.search_context skips empty lines"] = function()
  local items = parsers.search_context({
    "",
    "   ",
    "notes/only.md:1: ok",
  })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1].filename, "notes/only.md")
end

T["parsers.search_context skips malformed lines"] = function()
  local items = parsers.search_context({ "total: 12" })
  MiniTest.expect.equality(#items, 0)
end

T["parsers.search_context parses mixed-shape fixture"] = function()
  local spec_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local path = spec_dir .. "/fixtures/search_context.txt"
  local f = assert(io.open(path, "r"))
  local body = f:read("*a")
  f:close()
  local lines = vim.split(body, "\n", { plain = true })
  local items = parsers.search_context(lines)

  MiniTest.expect.equality(#items, 3)
  MiniTest.expect.equality(
    items[1],
    item("notes/foo.md", 42, "matched text")
  )
  MiniTest.expect.equality(
    items[2],
    item("notes/bar.md", 7, "prefix matched after space branch")
  )
  MiniTest.expect.equality(
    items[3],
    item("notes/baz.md", 13, "rest of text via tsv")
  )
end

T["parsers.paths parses a single path line"] = function()
  local items = parsers.paths({ "notes/foo.md" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1], item("notes/foo.md", 1, "notes/foo.md"))
end

T["parsers.paths parses multiple path lines in order"] = function()
  local items = parsers.paths({ "notes/foo.md", "notes/bar.md" })
  MiniTest.expect.equality(#items, 2)
  MiniTest.expect.equality(items[1], item("notes/foo.md", 1, "notes/foo.md"))
  MiniTest.expect.equality(items[2], item("notes/bar.md", 1, "notes/bar.md"))
end

T["parsers.paths skips empty and whitespace-only lines"] = function()
  local items = parsers.paths({ "", "   ", "\t", "notes/only.md" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1].filename, "notes/only.md")
end

T["parsers.paths skips the total trailer"] = function()
  local items = parsers.paths({ "total", "  total  " })
  MiniTest.expect.equality(#items, 0)
end

T["parsers.paths trims surrounding whitespace"] = function()
  local items = parsers.paths({ "  notes/spaced.md  " })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1].filename, "notes/spaced.md")
end

T["parsers.paths parses mixed-shape fixture"] = function()
  local spec_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local path = spec_dir .. "/fixtures/paths.txt"
  local f = assert(io.open(path, "r"))
  local body = f:read("*a")
  f:close()
  local lines = vim.split(body, "\n", { plain = true })
  local items = parsers.paths(lines)

  MiniTest.expect.equality(#items, 3)
  MiniTest.expect.equality(items[1], item("notes/alpha.md", 1, "notes/alpha.md"))
  MiniTest.expect.equality(items[2], item("notes/beta.md", 1, "notes/beta.md"))
  MiniTest.expect.equality(items[3], item("notes/spaced.md", 1, "notes/spaced.md"))
end

local function task_item(filename, lnum, text)
  return {
    filename = filename,
    lnum = lnum,
    col = 1,
    text = text,
    user_data = { obsidian_task_ref = filename .. ":" .. lnum },
  }
end

T["parsers.tasks_verbose parses a grouped block (lnum-colon-text)"] = function()
  local lines = {
    "notes/work.md",
    "  12: - [ ] Write the spec",
    "  18: - [ ] Land the PR",
  }
  local items = parsers.tasks_verbose(lines)
  MiniTest.expect.equality(#items, 2)
  MiniTest.expect.equality(items[1], task_item("notes/work.md", 12, "- [ ] Write the spec"))
  MiniTest.expect.equality(items[2], task_item("notes/work.md", 18, "- [ ] Land the PR"))
end

T["parsers.tasks_verbose parses a grouped block (lnum-space-text)"] = function()
  local lines = {
    "notes/work.md",
    "  5 Morning checklist",
  }
  local items = parsers.tasks_verbose(lines)
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1], task_item("notes/work.md", 5, "Morning checklist"))
end

T["parsers.tasks_verbose parses multiple header sections in sequence"] = function()
  local lines = {
    "notes/alpha.md",
    "  3: task alpha one",
    "notes/beta.md",
    "  7: task beta one",
    "  9: task beta two",
  }
  local items = parsers.tasks_verbose(lines)
  MiniTest.expect.equality(#items, 3)
  MiniTest.expect.equality(items[1], task_item("notes/alpha.md", 3, "task alpha one"))
  MiniTest.expect.equality(items[2], task_item("notes/beta.md", 7, "task beta one"))
  MiniTest.expect.equality(items[3], task_item("notes/beta.md", 9, "task beta two"))
end

T["parsers.tasks_verbose parses an inline path:line:text line outside any header"] = function()
  local items = parsers.tasks_verbose({ "notes/standalone.md:7: inline task" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1], task_item("notes/standalone.md", 7, "inline task"))
end

T["parsers.tasks_verbose does not treat a path.md:N:... line as a header"] = function()
  local items = parsers.tasks_verbose({ "notes/foo.md:42: x" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1].filename, "notes/foo.md")
  MiniTest.expect.equality(items[1].lnum, 42)
end

T["parsers.tasks_verbose does not treat a checkbox-shaped line as a header"] = function()
  local items = parsers.tasks_verbose({ "notes/foo.md - [ ] something" })
  MiniTest.expect.equality(#items, 0)
end

T["parsers.tasks_verbose populates user_data.obsidian_task_ref"] = function()
  local items1 = parsers.tasks_verbose({ "notes/a.md", "  3: task text" })
  MiniTest.expect.equality(items1[1].user_data.obsidian_task_ref, "notes/a.md:3")
  local items2 = parsers.tasks_verbose({ "notes/b.md:5: inline" })
  MiniTest.expect.equality(items2[1].user_data.obsidian_task_ref, "notes/b.md:5")
end

T["parsers.tasks_verbose skips empty and whitespace-only lines without resetting current_file"] = function()
  local lines = {
    "notes/work.md",
    "",
    "   ",
    "  4: still attached",
  }
  local items = parsers.tasks_verbose(lines)
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1], task_item("notes/work.md", 4, "still attached"))
end

T["parsers.tasks_verbose parses a mixed-shape fixture"] = function()
  local spec_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local path = spec_dir .. "/fixtures/tasks_verbose.txt"
  local f = assert(io.open(path, "r"))
  local body = f:read("*a")
  f:close()
  local lines = vim.split(body, "\n", { plain = true })
  local items = parsers.tasks_verbose(lines)

  MiniTest.expect.equality(#items, 5)
  MiniTest.expect.equality(items[1], task_item("notes/work.md", 12, "- [ ] Write the spec"))
  MiniTest.expect.equality(items[2], task_item("notes/work.md", 18, "- [ ] Land the PR"))
  MiniTest.expect.equality(items[3], task_item("notes/journal.md", 5, "Morning checklist"))
  MiniTest.expect.equality(items[4], task_item("notes/standalone.md", 7, "inline task"))
  MiniTest.expect.equality(items[5], task_item("notes/fake.md", 42, "artifact"))
end

return T
