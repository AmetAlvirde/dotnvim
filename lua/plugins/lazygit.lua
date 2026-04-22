-- lazygit.nvim: Terminal UI for git commands
return {
  "kdheepak/lazygit.nvim",
  lazy = false,
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { desc = "Git LazyGit" })
    vim.keymap.set("n", "<leader>gf", ":LazyGitFilter<CR>", { desc = "Git filter (LazyGit)" })
    vim.keymap.set("n", "<leader>gF", ":LazyGitFilterCurrentFile<CR>", { desc = "Git filter file (LazyGit)" })
  end,
}

