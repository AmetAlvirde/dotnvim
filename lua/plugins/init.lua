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
    lazy = false,
    config = function()
      vim.g.html_template_literals = 1
      vim.cmd("syntax on")
    end,
  },

  -- vim-javascript: Enhanced JavaScript syntax highlighting
  {
    "pangloss/vim-javascript",
    lazy = false,
    config = function()
      vim.g.javascript_plugin_jsdoc = 1
      vim.g.javascript_plugin_ng = 1
    end,
  },

  -- vim-jsx-pretty: Enhanced JSX/HTML syntax highlighting
  {
    "MaxMEllon/vim-jsx-pretty",
    lazy = false,
    config = function()
      vim.g.jsx_ext_required = 0
    end,
  },

  -- typescript-vim: TypeScript syntax highlighting
  {
    "leafgarland/typescript-vim",
    lazy = false,
    config = function()
      vim.g.typescript_indent_disable = 1
    end,
  },

  -- emmet-vim: Emmet support for HTML and CSS
  {
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
