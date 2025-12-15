-- lazygit.nvim: Terminal UI for git commands
return {
  "kdheepak/lazygit.nvim",
  lazy = false,
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })
    vim.keymap.set("n", "<leader>gf", ":LazyGitFilter<CR>", { desc = "Open LazyGit (filtered)" })
    vim.keymap.set("n", "<leader>gc", ":LazyGitConfig<CR>", { desc = "Open LazyGit config" })
    vim.keymap.set("n", "<leader>gF", ":LazyGitFilterCurrentFile<CR>", { desc = "Open LazyGit (current file)" })
  end,
}

