-- User commands (not autocmds).
-- Kept separate so `lua/config/autocmds.lua` stays focused on actual events.

local register = require("config.commands_registrar").register

-- Manual theme switching commands
vim.api.nvim_create_user_command("SolarizedToggle", function()
  require("colors.solarized").toggle()
end, { desc = "Toggle Solarized theme between dark and light" })

vim.api.nvim_create_user_command("SolarizedDark", function()
  require("colors.solarized").set_theme("dark")
end, { desc = "Set Solarized theme to dark mode" })

vim.api.nvim_create_user_command("SolarizedLight", function()
  require("colors.solarized").set_theme("light")
end, { desc = "Set Solarized theme to light mode" })

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

vim.api.nvim_create_user_command("ObsCLITaskToggle", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local success, msg = obscli.toggle_task_from_quickfix()
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "Toggle selected Obsidian task (from quickfix)" })

-- ===================================================
-- Obsidian CLI (commands-only; batch 1 feature #3)
-- ===================================================

vim.api.nvim_create_user_command("ObsCLIOrphans", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local success, msg = obscli.orphans_to_quickfix()
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "List Obsidian orphan notes into quickfix" })

vim.api.nvim_create_user_command("ObsCLIDeadends", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local success, msg = obscli.deadends_to_quickfix()
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "List Obsidian dead-end notes into quickfix" })

vim.api.nvim_create_user_command("ObsCLIUnresolved", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local success, msg = obscli.unresolved_to_quickfix()
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "List Obsidian unresolved links (verbose) into quickfix" })

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

vim.api.nvim_create_user_command("ObsCLIHistory", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local success, msg = obscli.history_list_current()
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "Show Obsidian local history for current file" })

vim.api.nvim_create_user_command("ObsCLIHistoryRead", function(opts)
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local v = opts.args
  if not v or vim.trim(v) == "" then
    v = vim.fn.input("History version to read (number): ")
  end

  local success, msg = obscli.history_read_current(v)
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "Read a local history version for current file", nargs = "?" })

vim.api.nvim_create_user_command("ObsCLIDiffFrom", function(opts)
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local v = opts.args
  if not v or vim.trim(v) == "" then
    v = vim.fn.input("Diff from local history version (number): ")
  end

  local success, msg = obscli.diff_current_from(v)
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "Diff current file against a local history version", nargs = "?" })

-- ===================================================
-- Obsidian CLI (commands-only; batch 1 feature #8)
-- ===================================================

vim.api.nvim_create_user_command("ObsCLIOutline", function(opts)
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local fmt = opts.args
  if not fmt or vim.trim(fmt) == "" then
    fmt = "tree"
  end

  local success, msg = obscli.outline_current({ format = fmt })
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "Show Obsidian outline for current file (default format=tree)", nargs = "?" })

-- ===================================================
-- Obsidian CLI (commands-only; batch 2 feature #11)
-- ===================================================

vim.api.nvim_create_user_command("ObsCLIBacklinks", function(opts)
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local path_arg = opts.args
  if path_arg and vim.trim(path_arg) == "" then
    path_arg = nil
  end

  local success, msg = obscli.backlinks_counts_to_quickfix(path_arg)
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, {
  desc = "List Obsidian backlinks with counts (JSON) into quickfix",
  nargs = "?",
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

vim.api.nvim_create_user_command("ObsCLIBookmarks", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local success, msg = obscli.bookmarks_list_verbose()
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "List Obsidian bookmarks (verbose) in a scratch buffer" })

vim.api.nvim_create_user_command("ObsCLIBookmarkAdd", function(opts)
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local title = vim.trim(opts.args or "")
  local success, msg = obscli.bookmark_add_current({ title = title ~= "" and title or nil })
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, {
  desc = "Add Obsidian bookmark for current note (optional title as args, else prompt)",
  nargs = "*",
})

