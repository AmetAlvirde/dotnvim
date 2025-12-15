-- vim-html-template-literals: Enhanced syntax highlighting for HTML within JavaScript template literals
return {
  "jonsmithers/vim-html-template-literals",
  lazy = false,
  config = function()
    vim.g.html_template_literals = 1
    vim.cmd("syntax on")
  end,
}

