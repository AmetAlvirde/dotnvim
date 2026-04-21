-- Markdown-specific buffer settings (moved from lua/config/autocmds.lua).
-- Runs after built-in filetype plugins; buffer is the current markdown buffer.

-- nvim-cmp is lazy-loaded on InsertEnter; require may fail on first FileType pass.
local function disable_cmp_in_buffer()
  local ok, cmp = pcall(require, "cmp")
  if not ok then
    return false
  end
  cmp.setup.buffer({
    enabled = false,
    sources = {}, -- Completely disable all sources
  })
  return true
end

if not disable_cmp_in_buffer() then
  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = 0,
    once = true,
    callback = function()
      disable_cmp_in_buffer()
    end,
  })
end

local luasnip = require("luasnip")

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
