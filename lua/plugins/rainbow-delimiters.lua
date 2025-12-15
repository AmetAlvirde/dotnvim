-- rainbow-delimiters: Rainbow parentheses and brackets using treesitter
return {
  "HiPhish/rainbow-delimiters.nvim",
  lazy = false,
  config = function()
    local rainbow_delimiters = require("rainbow-delimiters")
    
    vim.g.rainbow_delimiters = {
      strategy = {
        [""] = rainbow_delimiters.strategy["global"],
        vim = rainbow_delimiters.strategy["local"],
      },
      query = {
        [""] = "rainbow-delimiters",
        lua = "rainbow-blocks",
        javascript = "rainbow-delimiters-react",
        -- tsx and ts files should use rainbow-delimiters-react, but it's not working. So
        -- we use rainbow-delimiters instead.
        typescript = "rainbow-delimiters",
        tsx = "rainbow-delimiters",
        jsx = "rainbow-delimiters-react",
        -- rainbow-tags seems like a good idea, but I want to work on the solarized theme first.
        -- html = "rainbow-tags",
      },
      -- This will prevent rainbow colors on JSX angle brackets
      blacklist = { 'jsx_element', 'jsx_self_closing_element', 'jsx_fragment', 'template_string' }, 
      highlight = {
        "RainbowDelimiterYellow", 
        "RainbowDelimiterOrange",
        "RainbowDelimiterBlue",
        "RainbowDelimiterRed",
      },
    }
  end,
}

