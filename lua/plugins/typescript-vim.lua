-- typescript-vim: TypeScript syntax highlighting
return {
  "leafgarland/typescript-vim",
  lazy = false,
  config = function()
    vim.g.typescript_indent_disable = 1
  end,
}

