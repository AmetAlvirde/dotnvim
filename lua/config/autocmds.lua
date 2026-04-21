local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight on yank
local highlight_group = augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- resize splits if window got resized
autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- go to last loc when opening a buffer
autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close some filetypes with <q>
autocmd("FileType", {
  pattern = {
    "qf",
    "help",
    "man",
    "lspinfo",
    "spectre_panel",
    "lir",
    "DressingSelect",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- wrap and check for spell in text filetypes
autocmd("FileType", {
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false  -- Disable spell checking for markdown files
  end,
})

-- Enhanced markdown configuration for better writing experience
autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    
    -- Disable nvim-cmp autocomplete and snippets
    cmp.setup.buffer({
      enabled = false,
      sources = {}, -- Completely disable all sources
    })
    
    -- Completely disable LuaSnip for markdown files
    luasnip.config.set_config({ 
      enable_autosnippets = false,
      store_selection_keys = false,
    })
    
    -- Clear all snippet sources for this buffer
    vim.cmd("silent! lua require('luasnip').unlink_current()")
    
    -- Enable hard line wrapping at 80 characters for markdown
    vim.opt_local.textwidth = 80
    vim.opt_local.formatoptions = "tcroq" -- Enable text wrapping, comments, etc.
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.showbreak = "↪ "
    
    -- Enable auto-formatting on save for markdown files
    vim.opt_local.formatprg = "prettier --print-width 80 --prose-wrap always --tab-width 2"
  end,
})

-- Fix conceallevel for json files
autocmd({ "FileType" }, {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd({ "BufWritePre" }, {
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Auto-check for external file changes when focus returns to Neovim
autocmd({ "FocusGained", "BufEnter" }, {
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "" then -- Only for normal files, not special buffers
      vim.cmd("checktime")
    end
  end,
})

-- Handle Obsidian files more gracefully to prevent E13 errors
autocmd("BufWritePre", {
  pattern = "*.md",
  callback = function()
    -- Disable backup for markdown files to prevent E13 errors
    vim.opt_local.writebackup = false
    vim.opt_local.backup = false
  end,
})

-- Solarized theme auto-switching
local solarized_group = augroup("SolarizedTheme", { clear = true })

-- Auto-detect and apply theme on startup
autocmd("VimEnter", {
  callback = function()
    if vim.g.colors_name == "solarized" then
      require("colors.solarized").setup()
    end
  end,
  group = solarized_group,
})

-- Auto-detect theme changes (for macOS and Linux)
autocmd("FocusGained", {
  callback = function()
    if vim.g.colors_name == "solarized" then
      require("colors.solarized").setup()
    end
  end,
  group = solarized_group,
})

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

vim.api.nvim_create_user_command("ObsCLITasks", function()
  local ok, obscli = pcall(require, "utils.obsidian_cli")
  if not ok then
    vim.notify("Failed to load utils.obsidian_cli", vim.log.levels.ERROR)
    return
  end

  local success, msg = obscli.tasks_to_quickfix({ only_todo = true })
  if not success then
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  if msg and msg ~= "" then
    vim.notify(msg, vim.log.levels.INFO)
  end
end, { desc = "List Obsidian TODO tasks into quickfix" })

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
