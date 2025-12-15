-- vim-javascript: Enhanced JavaScript syntax highlighting
return {
  "pangloss/vim-javascript",
  lazy = false,
  config = function()
    vim.g.javascript_plugin_jsdoc = 1
    vim.g.javascript_plugin_ng = 1
  end,
}

