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

T["parsers.unresolved_verbose parses a single-source TSV line"] = function()
  local items = parsers.unresolved_verbose({ "some-link\t3\tnotes/source.md" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(
    items[1],
    item("notes/source.md", 1, "some-link (count=3) sources: notes/source.md")
  )
end

T["parsers.unresolved_verbose parses a comma-separated multi-source TSV line"] = function()
  local items = parsers.unresolved_verbose({ "link\t2\tnotes/a.md, notes/b.md" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(
    items[1],
    item("notes/a.md", 1, "link (count=2) sources: notes/a.md, notes/b.md")
  )
end

T["parsers.unresolved_verbose parses multiple TSV lines in order"] = function()
  local items = parsers.unresolved_verbose({
    "a\t1\tx.md",
    "b\t2\ty.md",
  })
  MiniTest.expect.equality(#items, 2)
  MiniTest.expect.equality(items[1], item("x.md", 1, "a (count=1) sources: x.md"))
  MiniTest.expect.equality(items[2], item("y.md", 1, "b (count=2) sources: y.md"))
end

T["parsers.unresolved_verbose falls back to empty-string filename on no-md-source"] = function()
  local items = parsers.unresolved_verbose({ "orphan-link\t1\tunknown" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1].filename, "")
  MiniTest.expect.equality(items[1].lnum, 1)
  MiniTest.expect.equality(items[1].col, 1)
  MiniTest.expect.equality(items[1].text, "orphan-link (count=1) sources: unknown")
end

T["parsers.unresolved_verbose skips lines with fewer than three tab parts"] = function()
  MiniTest.expect.equality(#parsers.unresolved_verbose({ "only-one-cell" }), 0)
  MiniTest.expect.equality(#parsers.unresolved_verbose({ "two\tcells" }), 0)
  MiniTest.expect.equality(#parsers.unresolved_verbose({ "" }), 0)
  MiniTest.expect.equality(#parsers.unresolved_verbose({ "   " }), 0)
end

T["parsers.unresolved_verbose skips empty and whitespace-only lines mixed with valid TSV"] = function()
  MiniTest.expect.equality(#parsers.unresolved_verbose(nil), 0)
  local items = parsers.unresolved_verbose({
    "",
    "   ",
    "mid\t3\tnotes/keep.md",
    "\t",
  })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(
    items[1],
    item("notes/keep.md", 1, "mid (count=3) sources: notes/keep.md")
  )
end

T["parsers.unresolved_verbose renders non-numeric count as empty in text"] = function()
  local items = parsers.unresolved_verbose({ "weird-link\tnotanum\tnotes/x.md" })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1].text, "weird-link (count=) sources: notes/x.md")
  MiniTest.expect.equality(items[1].filename, "notes/x.md")
end

T["parsers.unresolved_verbose preserves the full sources cell in text for four sources"] = function()
  local src = "notes/a.md, notes/b.md, notes/c.md, notes/d.md"
  local line = "link\t8\t" .. src
  local items = parsers.unresolved_verbose({ line })
  MiniTest.expect.equality(#items, 1)
  MiniTest.expect.equality(items[1].filename, "notes/a.md")
  MiniTest.expect.equality(items[1].text, "link (count=8) sources: " .. src)
end

T["parsers.unresolved_verbose parses mixed-shape fixture"] = function()
  local spec_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local path = spec_dir .. "/fixtures/unresolved_verbose.txt"
  local f = assert(io.open(path, "r"))
  local body = f:read("*a")
  f:close()
  local lines = vim.split(body, "\n", { plain = true })
  local items = parsers.unresolved_verbose(lines)

  MiniTest.expect.equality(#items, 4)
  MiniTest.expect.equality(
    items[1],
    item("notes/solo.md", 1, "solo (count=4) sources: notes/solo.md")
  )
  MiniTest.expect.equality(
    items[2],
    item("notes/m1.md", 1, "multi (count=2) sources: notes/m1.md, notes/m2.md")
  )
  MiniTest.expect.equality(items[3].filename, "")
  MiniTest.expect.equality(items[3].text, "nogood (count=1) sources: nowhere")
  MiniTest.expect.equality(
    items[4],
    item("notes/z.md", 1, "odd (count=) sources: notes/z.md")
  )
end

-- backlinks_json: flag-required cases (parent flag, load-bearing)

T["parsers.backlinks_json returns nil on non-JSON input (parse-failure branch)"] = function()
  MiniTest.expect.equality(parsers.backlinks_json("not json at all"), nil)
end

T["parsers.backlinks_json returns empty table on empty array [] (parse-success-but-no-rows branch)"] = function()
  local result = parsers.backlinks_json("[]")
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 0)
end

T["parsers.backlinks_json returns empty table on empty object {} (parse-success-but-no-rows branch)"] = function()
  local result = parsers.backlinks_json("{}")
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 0)
end

T['parsers.backlinks_json returns empty table on {"backlinks": []} (parse-success-but-no-rows branch)'] = function()
  local result = parsers.backlinks_json('{"backlinks": []}')
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 0)
end

-- backlinks_json: schema-tolerant matrix

T["parsers.backlinks_json returns nil on empty input"] = function()
  MiniTest.expect.equality(parsers.backlinks_json(""), nil)
end

T["parsers.backlinks_json returns nil on whitespace-only input"] = function()
  MiniTest.expect.equality(parsers.backlinks_json("   "), nil)
end

T["parsers.backlinks_json returns nil on nil input"] = function()
  MiniTest.expect.equality(parsers.backlinks_json(nil), nil)
end

T["parsers.backlinks_json succeeds via substring retry when JSON is preceded by noise"] = function()
  local result = parsers.backlinks_json('warning: stale cache\n{"a.md": 3}')
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "a.md", count = 3 })
end

T["parsers.backlinks_json returns nil when both decode and substring retry fail"] = function()
  MiniTest.expect.equality(parsers.backlinks_json("noise {bad json"), nil)
end

T["parsers.backlinks_json parses a top-level list of strings as paths with count = 1"] = function()
  local result = parsers.backlinks_json('["notes/a.md", "notes/b.md"]')
  MiniTest.expect.equality(#result, 2)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 1 })
  MiniTest.expect.equality(result[2], { path = "notes/b.md", count = 1 })
end

T["parsers.backlinks_json parses a top-level list of objects with path and count"] = function()
  local result = parsers.backlinks_json('[{"path": "notes/a.md", "count": 4}, {"path": "notes/b.md", "count": 2}]')
  MiniTest.expect.equality(#result, 2)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 4 })
  MiniTest.expect.equality(result[2], { path = "notes/b.md", count = 2 })
end

T["parsers.backlinks_json accepts field aliases for path and count"] = function()
  local result = parsers.backlinks_json('[{"file": "notes/a.md", "linkCount": 7}]')
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 7 })
end

T["parsers.backlinks_json falls back to count = 1 when count is missing"] = function()
  local result = parsers.backlinks_json('[{"path": "notes/a.md"}]')
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 1 })
end

T["parsers.backlinks_json clamps zero count to 1 without dropping the row"] = function()
  local result = parsers.backlinks_json('[{"path": "notes/a.md", "count": 0}]')
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 1 })
end

T["parsers.backlinks_json clamps negative count to 1 without dropping the row"] = function()
  local result = parsers.backlinks_json('[{"path": "notes/a.md", "count": -3}]')
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 1 })
end

T["parsers.backlinks_json drops rows with empty path"] = function()
  local result = parsers.backlinks_json('[{"path": "", "count": 5}, {"path": "notes/a.md", "count": 2}]')
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 2 })
end

T["parsers.backlinks_json drops rows with whitespace-only path"] = function()
  local result = parsers.backlinks_json('[{"path": "   ", "count": 5}]')
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 0)
end

T["parsers.backlinks_json parses object-key shape (.md keys with numeric values)"] = function()
  local result = parsers.backlinks_json('{"notes/a.md": 3, "notes/b.md": 1}')
  MiniTest.expect.equality(#result, 2)
  table.sort(result, function(a, b) return a.path < b.path end)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 3 })
  MiniTest.expect.equality(result[2], { path = "notes/b.md", count = 1 })
end

T["parsers.backlinks_json parses nested-list shape under backlinks key"] = function()
  local result = parsers.backlinks_json('{"backlinks": [{"path": "notes/a.md", "count": 2}]}')
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 2 })
end

T["parsers.backlinks_json parses nested-list shape under items key"] = function()
  local result = parsers.backlinks_json('{"items": [{"path": "notes/a.md", "count": 5}]}')
  MiniTest.expect.equality(#result, 1)
  MiniTest.expect.equality(result[1], { path = "notes/a.md", count = 5 })
end

T["parsers.backlinks_json returns empty table for top-level scalar JSON (number)"] = function()
  local result = parsers.backlinks_json("42")
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 0)
end

T["parsers.backlinks_json returns empty table for top-level scalar JSON (string)"] = function()
  local result = parsers.backlinks_json('"hello"')
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 0)
end

T["parsers.backlinks_json returns empty table for top-level scalar JSON (boolean)"] = function()
  local result = parsers.backlinks_json("true")
  MiniTest.expect.equality(type(result), "table")
  MiniTest.expect.equality(#result, 0)
end

T["parsers.backlinks_json parses mixed-shape fixture end-to-end"] = function()
  local spec_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local path = spec_dir .. "/fixtures/backlinks_json.txt"
  local f = assert(io.open(path, "r"))
  local text = f:read("*a")
  f:close()

  local result = parsers.backlinks_json(text)
  MiniTest.expect.equality(#result, 3)
  MiniTest.expect.equality(result[1], { path = "notes/alpha.md", count = 3 })
  MiniTest.expect.equality(result[2], { path = "notes/beta.md", count = 7 })
  MiniTest.expect.equality(result[3], { path = "notes/gamma.md", count = 1 })
end

return T
