-- vim-styled-components: Enhanced syntax highlighting for CSS within JavaScript template literals
return {
  "styled-components/vim-styled-components",
  lazy = false,
  branch = "main",
  config = function()
    vim.g.styled_components_css_in_js = 1
  end,
}

