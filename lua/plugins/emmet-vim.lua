-- emmet-vim: Emmet support for HTML and CSS
return {
  "mattn/emmet-vim",
  lazy = false,
  config = function()
    -- Enable emmet for various file types
    vim.g.user_emmet_leader_key = '<C-y>'
    vim.g.user_emmet_settings = {
      javascript = {
        extends = 'jsx',
        quote_char = '"',
      },
      typescript = {
        extends = 'jsx',
        quote_char = '"',
      },
    }
    
    -- Enable emmet for JavaScript and TypeScript files
    vim.g.user_emmet_install_global = 0
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
      callback = function()
        vim.cmd("EmmetInstall")
      end,
    })
  end,
}

