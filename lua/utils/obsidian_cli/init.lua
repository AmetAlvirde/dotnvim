local M = {}

local VAULT_ROOTS = require("config.vaults").paths()

local command = require("utils.obsidian_cli.command")
local shell = require("utils.obsidian_cli.shell")
local parsers = require("utils.obsidian_cli.parsers")
local presenter = require("utils.obsidian_cli.presenter")

local function abs_to_vault_relpath(abs_path)
  abs_path = abs_path and vim.loop.fs_realpath(abs_path) or abs_path
  if not abs_path or abs_path == "" then
    return nil, "Current buffer has no file path."
  end

  for _, root in ipairs(VAULT_ROOTS) do
    local real_root = vim.loop.fs_realpath(root) or root
    if abs_path:sub(1, #real_root) == real_root then
      local rel = abs_path:sub(#real_root + 1)
      rel = rel:gsub("^/", "")
      if rel == "" then
        return nil, "Buffer path is the vault root, not a file."
      end
      return rel, nil
    end
  end

  return nil, "File is not inside a known Obsidian vault root."
end

--- Resolve a vault-relative path to an absolute file path.
--- @return string|nil
local function vault_relpath_to_abs(rel)
  if not rel or rel == "" then
    return nil
  end
  rel = vim.trim(rel):gsub("^[\"'](.*)[\"']$", "%1")
  if rel:sub(1, 1) == "/" then
    local stat = vim.loop.fs_stat(rel)
    if stat and stat.type == "file" then
      return vim.loop.fs_realpath(rel) or rel
    end
    return nil
  end
  rel = rel:gsub("^/", ""):gsub("\\", "/")
  for _, root in ipairs(VAULT_ROOTS) do
    local real_root = vim.loop.fs_realpath(root) or root
    local candidate = real_root .. "/" .. rel
    local stat = vim.loop.fs_stat(candidate)
    if stat and stat.type == "file" then
      return vim.loop.fs_realpath(candidate) or candidate
    end
  end
  return nil
end

function M.orphans_to_quickfix()
  local lines, err = shell.run(command.orphans())
  if not lines then
    return false, err
  end
  return presenter.to_quickfix("Obsidian Orphans", parsers.paths(lines))
end

function M.deadends_to_quickfix()
  local lines, err = shell.run(command.deadends())
  if not lines then
    return false, err
  end
  return presenter.to_quickfix("Obsidian Deadends", parsers.paths(lines))
end

function M.unresolved_to_quickfix()
  local lines, err = shell.run(command.unresolved())
  if not lines then
    return false, err
  end

  local items = parsers.unresolved_verbose(lines)

  vim.fn.setqflist({}, " ", {
    title = "Obsidian Unresolved Links (verbose)",
    items = items,
  })

  if #items == 0 then
    if lines and #lines > 0 then
      presenter.scratch("ObsidianUnresolvedRawOutput", lines)
      return true, "No unresolved links parsed. Opened raw output buffer."
    end
    return true, "No unresolved links."
  end

  vim.cmd("copen")
  return true, string.format("Loaded %d unresolved link(s) into quickfix.", #items)
end

function M.search_context_to_quickfix(query)
  query = vim.trim(query or "")
  if query == "" then
    return false, "Query is required."
  end

  local lines, err = shell.run(command.search_context(query))
  if not lines then
    return false, err
  end

  local items = parsers.search_context(lines)

  vim.fn.setqflist({}, " ", {
    title = 'Obsidian Search Context: "' .. query .. '"',
    items = items,
  })

  if #items == 0 then
    if lines and #lines > 0 then
      presenter.scratch("ObsidianSearchContextRawOutput", lines)
      return true, "No search results parsed. Opened raw output buffer."
    end
    return true, "No matches."
  end

  vim.cmd("copen")
  return true, string.format("Loaded %d match(es) into quickfix.", #items)
end

function M.history_list_current()
  local rel, err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
  if not rel then
    return false, err
  end

  local lines, run_err = shell.run(command.history_list(rel))
  if not lines then
    return false, run_err
  end

  presenter.scratch("ObsidianHistory: " .. rel, lines)
  return true, "Opened history list for " .. rel
end

function M.history_read_current(version)
  local rel, err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
  if not rel then
    return false, err
  end

  local v = tonumber(version, 10) or 1
  local lines, run_err = shell.run(command.history_read(rel, v))
  if not lines then
    return false, run_err
  end

  presenter.scratch(string.format("ObsidianHistoryRead v%d: %s", v, rel), lines)
  return true, string.format("Opened version %d for %s", v, rel)
end

function M.diff_current_from(version)
  local rel, err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
  if not rel then
    return false, err
  end

  local v = tonumber(version, 10)
  if not v then
    return false, "Version number is required."
  end

  local lines, run_err = shell.run(command.diff(rel, v))
  if not lines then
    return false, run_err
  end

  presenter.scratch(string.format("ObsidianDiff Local#%d: %s", v, rel), lines)
  vim.bo.filetype = "diff"
  return true, string.format("Opened diff from Local #%d for %s", v, rel)
end

--- @param opts { format?: string }
function M.outline_current(opts)
  opts = opts or {}
  local fmt = vim.trim(opts.format or "tree")
  if fmt == "" then
    fmt = "tree"
  end

  local rel, err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
  if not rel then
    return false, err
  end

  local lines, run_err = shell.run(command.outline(rel, fmt))
  if not lines then
    return false, run_err
  end

  presenter.scratch(string.format("ObsidianOutline (%s): %s", fmt, rel), lines)
  if fmt == "md" then
    vim.bo.filetype = "markdown"
  end
  return true, string.format("Opened outline (%s) for %s", fmt, rel)
end

--- @param path_rel string|nil vault-relative path; defaults to current buffer
function M.backlinks_counts_to_quickfix(path_rel)
  local rel
  if path_rel and vim.trim(path_rel) ~= "" then
    rel = vim.trim(path_rel)
  else
    local r, err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
    if not r then
      return false, err
    end
    rel = r
  end

  local lines, run_err = shell.run(command.backlinks_counts(rel))
  if not lines then
    return false, run_err
  end

  local text = table.concat(lines, "\n")
  local rows = parsers.backlinks_json(text)

  if rows == nil then
    presenter.scratch("ObsidianBacklinksRawOutput", lines)
    return true, "Could not parse backlinks JSON. Opened raw CLI output."
  end

  if #rows == 0 then
    presenter.scratch("ObsidianBacklinksRawOutput", lines)
    return true, "No backlinks parsed from JSON. Opened raw CLI output."
  end

  local merged = {}
  for _, row in ipairs(rows) do
    merged[row.path] = (merged[row.path] or 0) + row.count
  end
  rows = {}
  for p, c in pairs(merged) do
    table.insert(rows, { path = p, count = c })
  end

  table.sort(rows, function(a, b)
    return a.path:lower() < b.path:lower()
  end)

  local items = {}
  for _, row in ipairs(rows) do
    table.insert(items, {
      filename = row.path,
      lnum = 1,
      col = 1,
      text = string.format("count=%d  %s", row.count, row.path),
    })
  end

  vim.fn.setqflist({}, " ", {
    title = "Obsidian Backlinks (counts): " .. rel,
    items = items,
  })

  vim.cmd("copen")
  return true, string.format("Loaded %d backlink source(s) for %s.", #items, rel)
end

--- @param opts { path_rel?: string, mode?: "full"|"words"|"characters" }
function M.wordcount_current(opts)
  opts = opts or {}
  local mode = opts.mode or "full"
  if mode ~= "words" and mode ~= "characters" then
    mode = "full"
  end

  local rel
  if opts.path_rel and vim.trim(opts.path_rel) ~= "" then
    rel = vim.trim(opts.path_rel)
  else
    local r, err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
    if not r then
      return false, err
    end
    rel = r
  end

  local lines, run_err = shell.run(command.wordcount(rel, mode))
  if not lines then
    return false, run_err
  end

  local text = vim.trim(table.concat(lines, "\n"))
  if text == "" then
    text = "(empty result)"
  end

  local long = #lines > 1 or (lines[1] and #lines[1] > 160)
  if long then
    presenter.scratch(string.format("ObsidianWordcount (%s): %s", mode, rel), lines)
    return true, string.format("Opened wordcount (%s) for %s", mode, rel)
  end

  return true, text
end

function M.bookmarks_list_verbose()
  local lines, err = shell.run(command.bookmarks_verbose())
  if not lines then
    return false, err
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "ObsidianBookmarks")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "text"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, buf)

  vim.keymap.set("n", "<CR>", function()
    local ln = vim.api.nvim_get_current_line()
    local rel = parsers.extract_bookmark_note_path(ln)
    if not rel then
      vim.notify("No note path found on this line.", vim.log.levels.WARN)
      return
    end
    local abs = vault_relpath_to_abs(rel)
    if not abs then
      vim.notify("Could not resolve note path: " .. rel, vim.log.levels.ERROR)
      return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(abs))
  end, { buffer = buf, desc = "Open bookmarked note" })

  return true, string.format("Opened bookmarks list (%d line(s)). Press <CR> on a line to open.", #lines)
end

--- @param opts { title?: string }
function M.bookmark_add_current(opts)
  opts = opts or {}
  local rel, path_err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
  if not rel then
    return false, path_err
  end

  local t = opts.title and vim.trim(opts.title) or ""
  local out_lines, run_err = shell.run(command.bookmark_add(rel, t ~= "" and t or nil))
  if run_err then
    return false, run_err
  end

  local suffix = ""
  if out_lines and #out_lines > 0 then
    suffix = "\n" .. table.concat(out_lines, "\n")
  end
  local msg = "Bookmark added for " .. rel .. (t ~= "" and (' title="' .. t .. '"') or "") .. suffix
  return true, vim.trim(msg)
end

--- @param opts { only_todo?: boolean, keep_task_ref?: string }
function M.tasks_to_quickfix(opts)
  opts = opts or {}
  local only_todo = opts.only_todo ~= false

  local lines, err = shell.run(command.tasks(opts))
  if not lines then
    return false, err
  end

  local items = parsers.tasks_verbose(lines)

  vim.fn.setqflist({}, " ", {
    title = only_todo and "Obsidian Tasks (todo)" or "Obsidian Tasks",
    items = items,
  })

  if #items == 0 then
    if lines and #lines > 0 then
      presenter.scratch("ObsidianTasksRawOutput", lines)
      return true, "No tasks parsed. Opened raw CLI output buffer for inspection."
    end
    return true, "No tasks found."
  end

  vim.cmd("copen")
  if opts.keep_task_ref and type(opts.keep_task_ref) == "string" and opts.keep_task_ref ~= "" then
    presenter.qf_focus_row_for_task_ref(opts.keep_task_ref)
  end
  return true, string.format("Loaded %d task(s) into quickfix.", #items)
end

function M.toggle_task_from_quickfix()
  local item = presenter.get_current_qf_item()
  if not item then
    return false, "No quickfix item selected."
  end

  local ref = nil
  if item.user_data and type(item.user_data) == "table" then
    ref = item.user_data.obsidian_task_ref
  end
  if not ref then
    local fname = item.filename or item.bufnr and vim.api.nvim_buf_get_name(item.bufnr) or nil
    local lnum = item.lnum or 1
    if fname and fname ~= "" then
      ref = string.format("%s:%d", fname, lnum)
    end
  end

  if not ref then
    return false, "Could not determine task ref for selected item."
  end

  local _, err = shell.run(command.task_toggle(ref))
  if err then
    return false, err
  end

  M.tasks_to_quickfix({ only_todo = false, keep_task_ref = ref })
  return true, "Toggled task: " .. ref
end

return M
