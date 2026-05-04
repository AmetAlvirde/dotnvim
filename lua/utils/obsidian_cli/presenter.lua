local M = {}

--- Open a scratch buffer showing `lines` in a bottom split.
--- @param title string buffer name
--- @param lines string[]
function M.scratch(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, title)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or {})
  vim.bo[buf].filetype = "text"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, buf)
end

--- Populate quickfix with `items` under `title` and open if non-empty.
--- @param title string
--- @param items table[]
--- @return boolean, string
function M.to_quickfix(title, items)
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

--- Return the quickfix window handle for the current tabpage, or nil.
--- @return integer|nil
function M.find_quickfix_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local w = vim.fn.getwininfo(win)[1]
    if w and w.quickfix == 1 and w.loclist == 0 then
      return win
    end
  end
  return nil
end

--- Find the quickfix row index for a task ref (`path.md:line`) after reload.
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

--- Sync quickfix index and cursor to the row for `ref` after a list rebuild.
--- @param ref string
function M.qf_focus_row_for_task_ref(ref)
  local idx = qf_idx_for_task_ref(ref)
  if not idx then
    return
  end
  vim.fn.setqflist({}, "a", { idx = idx })
  local win = M.find_quickfix_win()
  if win then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, { idx, 0 })
  end
end

--- Return the currently selected quickfix item, respecting cursor position
--- when called from inside the quickfix window.
--- @return table|nil
function M.get_current_qf_item()
  local items = vim.fn.getqflist()
  if not items or #items == 0 then
    return nil
  end

  local idx
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1] or {}
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

return M
