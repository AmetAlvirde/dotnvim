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
