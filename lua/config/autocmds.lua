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
