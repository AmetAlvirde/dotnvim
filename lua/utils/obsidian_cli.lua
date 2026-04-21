local M = {}

local VAULT_ROOTS = require("config.vaults").paths()

local function shellescape(s)
  return vim.fn.shellescape(s)
end

local function run_obsidian_cli(cmdline)
  -- cmdline is a string, e.g. `obsidian tasks todo verbose`
  local out = vim.fn.systemlist(cmdline)
  local code = vim.v.shell_error
  if code ~= 0 then
    local msg = table.concat(out or {}, "\n")
    if msg == "" then
      msg = string.format("obsidian-cli failed (exit %d). Is Obsidian running and CLI enabled?", code)
    end
    return nil, msg
  end
  return out, nil
end

local function parse_path_line_text(line)
  -- Supports:
  -- 1) `path/to/file.md:123: - [ ] ...`
  -- 2) `path/to/file.md:123 - [ ] ...`
  -- 3) `path/to/file.md\t123\t...` (tsv-ish)
  if not line or line == "" then
    return nil
  end

  local path, lnum, text = line:match("^(.-):(%d+):%s*(.*)$")
  if path and lnum then
    return { path = path, lnum = tonumber(lnum, 10) or 1, text = text }
  end

  path, lnum, text = line:match("^(.-):(%d+)%s+(.*)$")
  if path and lnum then
    return { path = path, lnum = tonumber(lnum, 10) or 1, text = text }
  end

  local parts = vim.split(line, "\t", { plain = true })
  if #parts >= 2 then
    local p = vim.trim(parts[1] or "")
    local n = tonumber(vim.trim(parts[2] or ""), 10)
    if p ~= "" and n then
      local rest = table.concat(vim.list_slice(parts, 3), "\t")
      return { path = p, lnum = n, text = vim.trim(rest) }
    end
  end

  return nil
end

local function tasks_verbose_to_items(lines)
  -- Obsidian CLI output formats observed:
  -- A) `path/to/file.md:123: - [ ] task`
  -- B) Grouped by file, e.g.:
  --      path/to/file.md
  --        123: - [ ] task
  --        456: - [ ] task
  local items = {}
  local current_file = nil

  for _, line in ipairs(lines or {}) do
    if line and line ~= "" then
      -- If line looks like a file header, remember it.
      -- We accept both `foo.md` and `folder/foo.md` (optionally wrapped in whitespace).
      local file_header = vim.trim(line)
      if file_header:match("%.md$") and not file_header:match(":%d+") and not file_header:match("%[%s*[xX %-%?]%s*%]") then
        current_file = file_header
      else
        local parsed = parse_path_line_text(line)
        if not parsed and current_file then
          -- Try `  123: text` and `  123 text`
          local lnum, text = line:match("^%s*(%d+):%s*(.*)$")
          if not lnum then
            lnum, text = line:match("^%s*(%d+)%s+(.*)$")
          end
          if lnum and text then
            parsed = { path = current_file, lnum = tonumber(lnum, 10) or 1, text = vim.trim(text) }
          end
        end

        if parsed then
          local ref = string.format("%s:%d", parsed.path, parsed.lnum)
          table.insert(items, {
            filename = parsed.path,
            lnum = parsed.lnum,
            col = 1,
            text = (parsed.text and parsed.text ~= "") and parsed.text or line,
            user_data = { obsidian_task_ref = ref },
          })
        end
      end
    end
  end

  return items
end

local function open_scratch(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, title)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or {})
  vim.bo[buf].filetype = "text"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, buf)
end

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

--- Resolve a vault-relative path (as returned by the CLI) to an absolute file path.
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

--- Pick a note path from a `obsidian bookmarks verbose` line (TSV-ish; paths may be quoted).
--- @return string|nil vault-relative or absolute path to a .md file
local function extract_bookmark_note_path(line)
  line = line or ""
  local cells = vim.split(line, "\t", { plain = true })
  for _, cell in ipairs(cells) do
    cell = vim.trim(cell):gsub("^[\"'](.*)[\"']$", "%1")
    if cell ~= "" and not cell:match("^https?:") then
      if vault_relpath_to_abs(cell) then
        return cell
      end
      if cell:match("%.md$") then
        return cell
      end
    end
  end
  local md = line:match("([%w%-%._/]+)%.md")
  if md then
    return md .. ".md"
  end
  return nil
end

local function paths_to_quickfix(title, lines)
  local items = {}
  for _, line in ipairs(lines or {}) do
    local p = vim.trim(line or "")
    if p ~= "" and not p:match("^%s*total%s*$") then
      table.insert(items, {
        filename = p,
        lnum = 1,
        col = 1,
        text = p,
      })
    end
  end

  vim.fn.setqflist({}, " ", {
    title = title,
    items = items,
  })

  if #items == 0 then
    return true, "No results."
  end
  vim.cmd("copen")
  return true, string.format("Loaded %d item(s) into quickfix.", #items)
end

function M.orphans_to_quickfix()
  local lines, err = run_obsidian_cli("obsidian orphans")
  if not lines then
    return false, err
  end
  return paths_to_quickfix("Obsidian Orphans", lines)
end

function M.deadends_to_quickfix()
  local lines, err = run_obsidian_cli("obsidian deadends")
  if not lines then
    return false, err
  end
  return paths_to_quickfix("Obsidian Deadends", lines)
end

function M.unresolved_to_quickfix()
  -- `unresolved verbose` prints: `<link>\t<count>\t<source1.md, source2.md>`
  local lines, err = run_obsidian_cli("obsidian unresolved verbose")
  if not lines then
    return false, err
  end

  local items = {}
  for _, line in ipairs(lines or {}) do
    if line and line ~= "" then
      local parts = vim.split(line, "\t", { plain = true })
      if #parts >= 3 then
        local link = vim.trim(parts[1] or "")
        local count = tonumber(vim.trim(parts[2] or ""), 10)
        local sources = vim.trim(parts[3] or "")

        -- Make it actionable: jump to the first source file if present.
        local first_source = sources:match("^%s*([^,%s]+%.md)%s*[, ]") or sources:match("^%s*([^,%s]+%.md)%s*$")

        if first_source and first_source ~= "" then
          table.insert(items, {
            filename = first_source,
            lnum = 1,
            col = 1,
            text = string.format("%s (count=%s) sources: %s", link, tostring(count or ""), sources),
          })
        else
          table.insert(items, {
            filename = "",
            lnum = 1,
            col = 1,
            text = string.format("%s (count=%s) sources: %s", link, tostring(count or ""), sources),
          })
        end
      end
    end
  end

  vim.fn.setqflist({}, " ", {
    title = "Obsidian Unresolved Links (verbose)",
    items = items,
  })

  if #items == 0 then
    if lines and #lines > 0 then
      open_scratch("ObsidianUnresolvedRawOutput", lines)
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

  local cmdline = "obsidian search:context query=" .. shellescape(query)
  local lines, err = run_obsidian_cli(cmdline)
  if not lines then
    return false, err
  end

  local items = {}
  for _, line in ipairs(lines or {}) do
    local parsed = parse_path_line_text(line)
    if parsed and parsed.path and parsed.lnum then
      table.insert(items, {
        filename = parsed.path,
        lnum = parsed.lnum,
        col = 1,
        text = parsed.text ~= "" and parsed.text or line,
      })
    end
  end

  vim.fn.setqflist({}, " ", {
    title = 'Obsidian Search Context: "' .. query .. '"',
    items = items,
  })

  if #items == 0 then
    if lines and #lines > 0 then
      open_scratch("ObsidianSearchContextRawOutput", lines)
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

  local lines, run_err = run_obsidian_cli("obsidian history path=" .. shellescape(rel))
  if not lines then
    return false, run_err
  end

  open_scratch("ObsidianHistory: " .. rel, lines)
  return true, "Opened history list for " .. rel
end

function M.history_read_current(version)
  local rel, err = abs_to_vault_relpath(vim.api.nvim_buf_get_name(0))
  if not rel then
    return false, err
  end

  local v = tonumber(version, 10) or 1
  local lines, run_err = run_obsidian_cli(
    "obsidian history:read path=" .. shellescape(rel) .. " version=" .. tostring(v)
  )
  if not lines then
    return false, run_err
  end

  open_scratch(string.format("ObsidianHistoryRead v%d: %s", v, rel), lines)
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

  local lines, run_err = run_obsidian_cli(
    "obsidian diff path=" .. shellescape(rel) .. " from=" .. tostring(v)
  )
  if not lines then
    return false, run_err
  end

  open_scratch(string.format("ObsidianDiff Local#%d: %s", v, rel), lines)
  -- Mark buffer as diff for nicer highlighting.
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

  local cmdline = "obsidian outline path=" .. shellescape(rel) .. " format=" .. fmt
  local lines, run_err = run_obsidian_cli(cmdline)
  if not lines then
    return false, run_err
  end

  open_scratch(string.format("ObsidianOutline (%s): %s", fmt, rel), lines)
  if fmt == "md" then
    vim.bo.filetype = "markdown"
  end
  return true, string.format("Opened outline (%s) for %s", fmt, rel)
end

--- Decode `obsidian backlinks ... counts format=json` output; schema may vary by CLI version.
local function try_decode_json_object(text)
  text = vim.trim(text or "")
  if text == "" then
    return nil
  end
  local ok, data = pcall(vim.json.decode, text)
  if ok and data ~= nil then
    return data
  end
  local start = text:find("[%[%{]")
  if start then
    ok, data = pcall(vim.json.decode, text:sub(start))
    if ok and data ~= nil then
      return data
    end
  end
  return nil
end

--- @return { path: string, count: integer }[]
local function backlinks_json_to_rows(data)
  local rows = {}

  local function add(path, count)
    path = vim.trim(tostring(path or ""))
    if path == "" then
      return
    end
    count = tonumber(count)
    if not count or count < 1 then
      count = 1
    end
    table.insert(rows, { path = path, count = count })
  end

  local function from_item(item)
    if type(item) == "string" then
      if vim.trim(item) ~= "" then
        add(item, 1)
      end
      return
    end
    if type(item) ~= "table" then
      return
    end
    local p = item.path or item.file or item.filePath or item.filepath or item.source or item.from or item.name
    if type(p) ~= "string" then
      return
    end
    local c = item.count or item.linkCount or item.links or item.total or item.n
    add(p, c)
  end

  if type(data) ~= "table" then
    return rows
  end

  if vim.tbl_islist(data) then
    for _, item in ipairs(data) do
      from_item(item)
    end
    return rows
  end

  local nested = data.backlinks or data.links or data.items or data.results or data.files
  if type(nested) == "table" and vim.tbl_islist(nested) then
    for _, item in ipairs(nested) do
      from_item(item)
    end
    if #rows > 0 then
      return rows
    end
  end

  for k, v in pairs(data) do
    if type(k) == "string" and k:match("%.md") and type(v) == "number" then
      add(k, v)
    elseif type(v) == "table" then
      from_item(v)
    elseif type(v) == "string" and v:match("%.md") then
      add(v, 1)
    end
  end

  return rows
end

--- List backlinks with per-source counts (CLI JSON) into quickfix.
--- @param path_rel string|nil Vault-relative path; defaults to current buffer.
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

  local cmdline = "obsidian backlinks path=" .. shellescape(rel) .. " counts format=json"
  local lines, run_err = run_obsidian_cli(cmdline)
  if not lines then
    return false, run_err
  end

  local text = table.concat(lines, "\n")
  local data = try_decode_json_object(text)
  if not data then
    open_scratch("ObsidianBacklinksRawOutput", lines)
    return true, "Could not parse backlinks JSON. Opened raw CLI output."
  end

  local rows = backlinks_json_to_rows(data)
  if #rows == 0 then
    open_scratch("ObsidianBacklinksRawOutput", lines)
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

  local cmdline = "obsidian wordcount path=" .. shellescape(rel)
  if mode == "words" then
    cmdline = cmdline .. " words"
  elseif mode == "characters" then
    cmdline = cmdline .. " characters"
  end

  local lines, run_err = run_obsidian_cli(cmdline)
  if not lines then
    return false, run_err
  end

  local text = vim.trim(table.concat(lines, "\n"))
  if text == "" then
    text = "(empty result)"
  end

  local long = #lines > 1 or (lines[1] and #lines[1] > 160)
  if long then
    open_scratch(string.format("ObsidianWordcount (%s): %s", mode, rel), lines)
    return true, string.format("Opened wordcount (%s) for %s", mode, rel)
  end

  return true, text
end

function M.bookmarks_list_verbose()
  local lines, err = run_obsidian_cli("obsidian bookmarks verbose")
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
    local rel = extract_bookmark_note_path(ln)
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

  local cmdline = "obsidian bookmark file=" .. shellescape(rel)
  local t = opts.title and vim.trim(opts.title) or ""
  if t ~= "" then
    cmdline = cmdline .. " title=" .. shellescape(t)
  end

  local out_lines, run_err = run_obsidian_cli(cmdline)
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

local function find_quickfix_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local w = vim.fn.getwininfo(win)[1]
    if w and w.quickfix == 1 and w.loclist == 0 then
      return win
    end
  end
  return nil
end

--- Find quickfix row index for a task ref (`path.md:line`) after reload.
--- @param ref string
--- @return integer|nil
local function qf_idx_for_task_ref(ref)
  if not ref or ref == "" then
    return nil
  end
  local items = vim.fn.getqflist()
  for i, item in ipairs(items) do
    local ud = item.user_data
    if type(ud) == "table" and ud.obsidian_task_ref == ref then
      return i
    end
  end
  local path, lnum_s = ref:match("^(.-):(%d+)$")
  local lnum = path and tonumber(lnum_s, 10) or nil
  if path and lnum then
    for i, item in ipairs(items) do
      if item.filename == path and item.lnum == lnum then
        return i
      end
    end
    local tail = path:match("[^/]+$") or path
    for i, item in ipairs(items) do
      local fname = item.filename or ""
      local tail_ok = tail ~= "" and #fname >= #tail and fname:sub(-#tail) == tail
      if item.lnum == lnum and (fname == path or tail_ok) then
        return i
      end
    end
  end
  return nil
end

--- Sync quickfix index and cursor to the row for `ref` (after list rebuild).
local function qf_focus_row_for_task_ref(ref)
  local idx = qf_idx_for_task_ref(ref)
  if not idx then
    return
  end
  vim.fn.setqflist({}, "a", { idx = idx })
  local win = find_quickfix_win()
  if win then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, { idx, 0 })
  end
end

--- @param opts { only_todo?: boolean, keep_task_ref?: string }
function M.tasks_to_quickfix(opts)
  opts = opts or {}
  local only_todo = opts.only_todo ~= false

  local cmd = { "obsidian", "tasks" }
  if only_todo then
    table.insert(cmd, "todo")
  end
  table.insert(cmd, "verbose")

  local cmdline = table.concat(cmd, " ")
  local lines, err = run_obsidian_cli(cmdline)
  if not lines then
    return false, err
  end

  local items = tasks_verbose_to_items(lines)

  vim.fn.setqflist({}, " ", {
    title = only_todo and "Obsidian Tasks (todo)" or "Obsidian Tasks",
    items = items,
  })

  if #items == 0 then
    if lines and #lines > 0 then
      open_scratch("ObsidianTasksRawOutput", lines)
      return true, "No tasks parsed. Opened raw CLI output buffer for inspection."
    end
    return true, "No tasks found."
  end

  vim.cmd("copen")
  if opts.keep_task_ref and type(opts.keep_task_ref) == "string" and opts.keep_task_ref ~= "" then
    qf_focus_row_for_task_ref(opts.keep_task_ref)
  end
  return true, string.format("Loaded %d task(s) into quickfix.", #items)
end

local function get_current_qf_item()
  local items = vim.fn.getqflist()
  if not items or #items == 0 then
    return nil
  end

  local idx
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1] or {}
  -- Cursor position in the quickfix window does not update `idx`; use line('.') here.
  if wininfo.quickfix == 1 and wininfo.loclist == 0 then
    idx = vim.fn.line(".")
  else
    idx = vim.fn.getqflist({ idx = 0 }).idx or 0
  end

  if idx < 1 or idx > #items then
    return nil
  end
  return items[idx]
end

function M.toggle_task_from_quickfix()
  local item = get_current_qf_item()
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

  local cmdline = "obsidian task ref=" .. shellescape(ref) .. " toggle"
  local _, err = run_obsidian_cli(cmdline)
  if err then
    return false, err
  end

  -- Reload list so status reflects changes; keep cursor on this task row.
  M.tasks_to_quickfix({ only_todo = false, keep_task_ref = ref })
  return true, "Toggled task: " .. ref
end

return M

