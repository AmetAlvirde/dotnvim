local M = {}

local function shellescape(s)
  return vim.fn.shellescape(s)
end

M.shellescape = shellescape

--- @param opts { only_todo?: boolean }
function M.tasks(opts)
  opts = opts or {}
  local only_todo = opts.only_todo ~= false
  local parts = { "obsidian", "tasks" }
  if only_todo then
    table.insert(parts, "todo")
  end
  table.insert(parts, "verbose")
  return table.concat(parts, " ")
end

function M.orphans()
  return "obsidian orphans"
end

function M.deadends()
  return "obsidian deadends"
end

function M.unresolved()
  return "obsidian unresolved verbose"
end

--- @param query string
function M.search_context(query)
  return "obsidian search:context query=" .. shellescape(query)
end

--- @param rel string vault-relative path
function M.history_list(rel)
  return "obsidian history path=" .. shellescape(rel)
end

--- @param rel string vault-relative path
--- @param v integer version number
function M.history_read(rel, v)
  return "obsidian history:read path=" .. shellescape(rel) .. " version=" .. tostring(v)
end

--- @param rel string vault-relative path
--- @param v integer version number
function M.diff(rel, v)
  return "obsidian diff path=" .. shellescape(rel) .. " from=" .. tostring(v)
end

--- @param rel string vault-relative path
--- @param fmt string outline format
function M.outline(rel, fmt)
  return "obsidian outline path=" .. shellescape(rel) .. " format=" .. fmt
end

--- @param rel string vault-relative path
function M.backlinks_counts(rel)
  return "obsidian backlinks path=" .. shellescape(rel) .. " counts format=json"
end

--- @param rel string vault-relative path
--- @param mode string "full"|"words"|"characters"
function M.wordcount(rel, mode)
  local cmdline = "obsidian wordcount path=" .. shellescape(rel)
  if mode == "words" then
    cmdline = cmdline .. " words"
  elseif mode == "characters" then
    cmdline = cmdline .. " characters"
  end
  return cmdline
end

function M.bookmarks_verbose()
  return "obsidian bookmarks verbose"
end

--- @param rel string vault-relative path
--- @param title string|nil optional bookmark title
function M.bookmark_add(rel, title)
  local cmdline = "obsidian bookmark file=" .. shellescape(rel)
  local t = title and vim.trim(title) or ""
  if t ~= "" then
    cmdline = cmdline .. " title=" .. shellescape(t)
  end
  return cmdline
end

--- @param ref string task ref in "path.md:line" format
function M.task_toggle(ref)
  return "obsidian task ref=" .. shellescape(ref) .. " toggle"
end

return M
