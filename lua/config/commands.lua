-- User commands (not autocmds).
-- Kept separate so `lua/config/autocmds.lua` stays focused on actual events.

local register = require("config.commands_registrar").register

-- Manual theme switching commands
register({
  name = "SolarizedToggle",
  desc = "Toggle Solarized theme between dark and light",
  module = "colors.solarized",
  fn = "toggle",
  kind = "void"
})

register({
  name = "SolarizedDark",
  desc = "Set Solarized theme to dark mode",
  module = "colors.solarized",
  fn = "set_theme",
  kind = "void",
  args = function(_) return { "dark" }  end
})

register({
  name = "SolarizedLight",
  desc = "Set Solarized theme to light mode",
  module = "colors.solarized",
  fn = "set_theme",
  kind = "void",
  args = function(_) return { "light" } end
})

-- ===================================================
-- Obsidian CLI (commands-only; batch 1 feature #2)
-- ===================================================

register({
  name = "ObsCLITasks",
  desc = "List Obsidian TODO tasks into quickfix",
  module = "utils.obsidian_cli",
  fn = "tasks_to_quickfix",
  args = function(_) return { { only_todo = true } } end,
})

register({
  name = "ObsCLITaskToggle",
  desc = "Toggle selected Obsidian task (from quickfix)",
  module = "utils.obsidian_cli",
  fn = "toggle_task_from_quickfix",
})

-- ===================================================
-- Obsidian CLI (commands-only; batch 1 feature #3)
-- ===================================================

register({
  name = "ObsCLIOrphans",
  desc = "List Obsidian orphan notes into quickfix",
  module = "utils.obsidian_cli",
  fn = "orphans_to_quickfix",
})

register({
  name = "ObsCLIDeadends",
  desc = "List Obsidian dead-end notes into quickfix",
  module = "utils.obsidian_cli",
  fn = "deadends_to_quickfix",
})

register({
  name = "ObsCLIUnresolved",
  desc = "List Obsidian unresolved links (verbose) into quickfix",
  module = "utils.obsidian_cli",
  fn = "unresolved_to_quickfix",
})

-- ===================================================
-- Obsidian CLI (commands-only; batch 1 feature #5)
-- ===================================================

vim.api.nvim_create_user_command("ObsCLISearchContext", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local query = vim.fn.input("Obsidian search query: ")
  if not query or vim.trim(query) == "" then
    vim.notify("Search query required.", vim.log.levels.WARN)
    return
  end

  local success, msg = obscli.search_context_to_quickfix(query)
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "Search Obsidian vault with context (quickfix)" })

-- ===================================================
-- Obsidian CLI (commands-only; batch 1 feature #6)
-- ===================================================

register({
  name = "ObsCLIHistory",
  desc = "Show Obsidian local history for current file",
  module = "utils.obsidian_cli",
  fn = "history_list_current",
})

register({
  name = "ObsCLIHistoryRead",
  desc = "Read a local history version for current file",
  module = "utils.obsidian_cli",
  fn = "history_read_current",
  nargs = "?",
  args = function(cmd_opts)
    local v = cmd_opts.args
    if not v or vim.trim(v) == "" then
      v = vim.fn.input("History version to read (number): ")
    end
    return { v }
  end,
})

register({
  name = "ObsCLIDiffFrom",
  desc = "Diff current file against a local history version",
  module = "utils.obsidian_cli",
  fn = "diff_current_from",
  nargs = "?",
  args = function(cmd_opts)
    local v = cmd_opts.args
    if not v or vim.trim(v) == "" then
      v = vim.fn.input("Diff from local history version (number): ")
    end
    return { v }
  end,
})

-- ===================================================
-- Obsidian CLI (commands-only; batch 1 feature #8)
-- ===================================================

register({
  name = "ObsCLIOutline",
  desc = "Show Obsidian outline for current file (default format=tree)",
  module = "utils.obsidian_cli",
  fn = "outline_current",
  nargs = "?",
  args = function(cmd_opts)
    local fmt = cmd_opts.args
    if not fmt or vim.trim(fmt) == "" then
      fmt = "tree"
    end
    return { { format = fmt } }
  end,
})

-- ===================================================
-- Obsidian CLI (commands-only; batch 2 feature #11)
-- ===================================================

register({
  name = "ObsCLIBacklinks",
  desc = "List Obsidian backlinks with counts (JSON) into quickfix",
  module = "utils.obsidian_cli",
  fn = "backlinks_counts_to_quickfix",
  nargs = "?",
  args = function(cmd_opts)
    local path_arg = cmd_opts.args
    if path_arg and vim.trim(path_arg) == "" then
      path_arg = nil
    end
    return { path_arg }
  end,
})

-- ===================================================
-- Buffer word count (whitespace-separated words)
-- ===================================================

vim.api.nvim_create_user_command("WordCount", function(opts)
  local ok, wc = pcall(require, "utils.wordcount")
  if not ok then
    vim.notify("Failed to load utils.wordcount", vim.log.levels.ERROR)
    return
  end
  local n = wc.buf_line_range_wordcount(0, opts.line1, opts.line2)
  vim.notify(
    string.format("%d word%s (lines %d–%d)", n, n == 1 and "" or "s", opts.line1, opts.line2),
    vim.log.levels.INFO
  )
end, {
  range = true,
  desc = "Count whitespace-separated words in range (default: current line; use % or '<,'>)",
})

-- ===================================================
-- Obsidian CLI (commands-only; batch 2 feature #13)
-- ===================================================

vim.api.nvim_create_user_command("ObsCLIWordCount", function(opts)
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local fargs = opts.fargs or {}
  local path_parts = {}
  for i, v in ipairs(fargs) do
    path_parts[i] = v
  end

  local mode = "full"
  local n = #path_parts
  if n > 0 then
    local last = path_parts[n]:lower()
    if last == "words" or last == "word" then
      mode = "words"
      table.remove(path_parts, n)
    elseif last == "characters" or last == "chars" or last == "character" then
      mode = "characters"
      table.remove(path_parts, n)
    end
  end

  local path_rel = nil
  if #path_parts > 0 then
    path_rel = table.concat(path_parts, " ")
  end

  local success, msg = obscli.wordcount_current({ path_rel = path_rel, mode = mode })
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, {
  desc = "Obsidian wordcount (optional vault path; optional trailing words|characters)",
  nargs = "*",
})

-- ===================================================
-- Obsidian CLI (commands-only; batch 2 feature #15)
-- ===================================================

register({
  name = "ObsCLIBookmarks",
  desc = "List Obsidian bookmarks (verbose) in a scratch buffer",
  module = "utils.obsidian_cli",
  fn = "bookmarks_list_verbose",
})

register({
  name = "ObsCLIBookmarkAdd",
  desc = "Add Obsidian bookmark for current note (optional title as args, else prompt)",
  module = "utils.obsidian_cli",
  fn = "bookmark_add_current",
  nargs = "*",
  args = function(cmd_opts)
    local title = vim.trim(cmd_opts.args or "")
    return { { title = title ~= "" and title or nil } }
  end,
})

