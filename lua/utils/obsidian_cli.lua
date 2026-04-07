local M = {}

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
  return true, string.format("Loaded %d task(s) into quickfix.", #items)
end

local function get_current_qf_item()
  local qf = vim.fn.getqflist({ idx = 0, items = 0 })
  local idx = qf and qf.idx or 0
  local items = qf and qf.items or {}
  local item = items[idx]
  return item
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

  -- Reload list so status reflects changes.
  M.tasks_to_quickfix({ only_todo = false })
  return true, "Toggled task: " .. ref
end

return M

