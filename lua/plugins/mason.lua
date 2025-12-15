-- mason.nvim: LSP server installer and manager
return {
  "williamboman/mason.nvim",
  lazy = false,
  priority = 100,
  config = function()
    require("mason").setup({
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      }
    })
  end,
}

