-- fugitive: Full Git integration
return {
  "tpope/vim-fugitive",
  lazy = false,
  config = function()
    -- Keymaps for common Fugitive commands
    vim.keymap.set('n', '<leader>gs', ':Git<CR>', { desc = 'Git status' })
    vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', { desc = 'Git commit' })
    vim.keymap.set('n', '<leader>gp', ':Git push<CR>', { desc = 'Git push' })
    vim.keymap.set('n', '<leader>gl', ':Git pull<CR>', { desc = 'Git pull' })
    vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { desc = 'Git blame' })
    vim.keymap.set('n', '<leader>gd', ':Gdiffsplit<CR>', { desc = 'Git diff split' })
    vim.keymap.set('n', '<leader>gw', ':Gwrite<CR>', { desc = 'Git write (stage)' })
    vim.keymap.set('n', '<leader>gr', ':Gread<CR>', { desc = 'Git read (checkout)' })
  end,
}

