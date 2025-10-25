return {
  -- ===================================================
  -- Essential Plugins (Recommended to start with these)
  -- ===================================================
  
  -- You can add plugins here. For example:
  
  -- Colorscheme (uncomment to use)
  -- { "folke/tokyonight.nvim", priority = 1000 },
  
  -- { "nvim-tree/nvim-tree.lua" },                 -- File tree
  -- { "tpope/vim-commentary" },                    -- Comment/uncomment code
  
  -- vim-tmux-navigator: Seamless navigation between tmux panes and vim windows
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    config = function()
      -- This plugin automatically handles the keymaps
      -- It will navigate within vim windows, and pass through to tmux when at boundaries
    end,
  },

  -- vim-html-template-literals: Enhanced syntax highlighting for HTML within JavaScript template literals
  {
    "jonsmithers/vim-html-template-literals",
    lazy = false, -- Load immediately for syntax highlighting
    config = function()
      -- Enable the plugin
      vim.g.html_template_literals = 1
      -- Force syntax highlighting
      vim.cmd("syntax on")
    end,
  },

  -- Alternative: vim-jsx-pretty for better JSX/HTML syntax highlighting
  {
    "MaxMEllon/vim-jsx-pretty",
    lazy = false,
    config = function()
      -- Enable JSX syntax highlighting
      vim.g.jsx_ext_required = 0
    end,
  },

  -- Additional: vim-javascript for better JavaScript syntax
  {
    "pangloss/vim-javascript",
    lazy = false,
    config = function()
      -- Enable JavaScript syntax highlighting
      vim.g.javascript_plugin_jsdoc = 1
      vim.g.javascript_plugin_ng = 1
    end,
  },

  -- Better template literal support
  {
    "leafgarland/typescript-vim",
    lazy = false,
    config = function()
      -- Enable TypeScript syntax highlighting
      vim.g.typescript_indent_disable = 1
    end,
  },
  
  -- ===================================================
  -- Plugin Structure:
  -- ===================================================
  -- {
  --   "username/repo-name",  -- GitHub repository
  --   lazy = true,           -- Load plugin lazily (load when triggered)
  --   version = "*",         -- Use latest version, or pin a specific version
  --   config = function()    -- Configuration for the plugin
  --     require("plugin-name").setup({
  --       -- options here
  --     })
  --   end,
  -- }
  
  -- For more examples and configuration, check out:
  -- https://github.com/folke/lazy.nvim
}
