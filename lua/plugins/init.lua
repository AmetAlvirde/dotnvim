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

  -- vim-styled-components: Enhanced syntax highlighting for CSS within JavaScript template literals
  {
    "styled-components/vim-styled-components",
    lazy = false,
    branch = "main",
    config = function()
      vim.g.styled_components_css_in_js = 1
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
  -- File Explorer Plugins
  -- ===================================================
  
  -- neo-tree: Modern file explorer (similar to VSCode)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          components = {
            name = function(config, node, state)
              local result = require("neo-tree.sources.common.components").name(config, node, state)
              if node.type == "directory" and node:get_id() == state.path then
                -- This is the root directory, show only basename
                result.text = vim.fn.fnamemodify(state.path, ":t")
              end
              return result
            end,
          },
        },
        window = {
          position = "right",
          width = 30,
        },
        -- Set default source to filesystem
        default_source = "filesystem",
      })
    end,
  },

  -- oil.nvim: Buffer-based file explorer
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        -- Oil will take over directory buffers (e.g. `vim .` or `:e dir/`)
        -- Set to false if you still want to use netrw.
        default_file_explorer = true,
        -- Idle timeout in milliseconds. When the file explorer is idle for this long, it will close.
        -- Set to false to disable the timeout.
        idle_timeout = 2000,
        -- Whether to delete hidden buffers after they are no longer displayed.
        cleanup_delay_ms = 2000,
        -- Set to true to automatically delete a buffer when it's no longer displayed.
        delete_hidden_buffers_on_close = false,
        -- Restore window options to previous values when leaving an oil buffer
        restore_win_options = true,
        -- Skip the confirmation popup for simple operations
        skip_confirm_for_simple_edits = false,
        -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
        prompt_save_on_select_new_entry = true,
        -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
        -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "i" })
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-s>"] = "actions.select_vsplit",
          ["<C-h>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<C-l>"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = "actions.tcd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["g\\"] = "actions.toggle_trash",
        },
        -- Set to false to disable all of the above keymaps
        use_default_keymaps = true,
        view_options = {
          -- Show files and directories that start with a dot
          show_hidden = false,
          -- This function defines what is considered a "hidden" file
          is_hidden_file = function(name, bufnr)
            return vim.startswith(name, ".")
          end,
          -- This function defines what will never be shown, even when `show_hidden` is set
          is_always_hidden = function(name, bufnr)
            return false
          end,
          sort = {
            -- sort order can be "asc" or "desc"
            -- see :help oil-columns to see which columns are sortable
            { "type", "asc" },
            { "name", "asc" },
          },
        },
        -- Configuration for the floating window in oil.nvim.float
        float = {
          -- Padding around the floating window
          padding = 2,
          max_width = 0,
          max_height = 0,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },
        -- Configuration for the actions floating window
        actions = {
          -- When true, show a floating window with the selected file's information
          show_file_info = true,
        },
        -- Configuration for the progress window
        progress = {
          max_width = 0.9,
          min_width = { 40, 0.4 },
          width = nil,
          max_height = { 10, 0.9 },
          min_height = { 5, 0.2 },
          height = nil,
          border = "rounded",
          minimized_border = "none",
          win_options = {
            winblend = 0,
          },
        },
        -- Configuration for the preview window
        preview = {
          -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.5 for 50%)
          -- min_width and max_width can be a single value or a list of mixed integer/float types.
          -- max_width = {100, 0.8} means "the lesser of 100 columns or 80% of total"
          max_width = 0.9,
          min_width = { 40, 0.4 },
          width = nil,
          -- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.5 for 50%)
          -- min_height and max_height can be a single value or a list of mixed integer/float types.
          -- max_height = {80, 0.9} means "the lesser of 80 columns or 90% of total"
          max_height = 0.9,
          min_height = { 5, 0.2 },
          height = nil,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
          -- Whether the preview window is automatically updated when the cursor is moved
          update_on_cursor_moved = true,
        },
        -- Configuration for the floating SSH window
        ssh = {
          -- Whether the SSH window is automatically updated when the cursor is moved
          update_on_cursor_moved = true,
        },
      })
    end,
  },

  -- ===================================================
  -- Telescope Plugin
  -- ===================================================
  
  -- telescope.nvim: Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = {
            "node_modules/",
            "build/",
            ".git/",
            ".DS_Store",
            "*.pyc",
            "__pycache__/",
            "*.so",
            "*.dylib",
            "*.dll",
            "*.exe",
            "*.o",
            "*.obj",
            "*.a",
            "*.lib",
            "*.so.*",
            "*.dylib.*",
            "*.dll.*",
            "*.exe.*",
            "*.o.*",
            "*.obj.*",
            "*.a.*",
            "*.lib.*",
          },
          mappings = {
            i = {
              ["<C-k>"] = require("telescope.actions").move_selection_previous,
              ["<C-j>"] = require("telescope.actions").move_selection_next,
            },
          },
        },
      })
      require("telescope").load_extension("fzf")
    end,
  },

  -- telescope-fzf-native: FZF sorter for telescope (better performance)
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    lazy = true,
  },

  -- ===================================================
  -- LSP (Language Server Protocol) Plugins
  -- ===================================================

  -- mason.nvim: LSP server installer and manager
  {
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
  },

  -- nvim-lspconfig: Core LSP configuration plugin
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      -- Using modern vim.lsp.config API (Neovim 0.11+)
      
      -- LSP Keybindings (set up on LspAttach event)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          
          -- Navigation
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Go to declaration' }))
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Go to references' }))
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = 'Go to implementation' }))
          vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, vim.tbl_extend('force', opts, { desc = 'Go to type definition' }))
          
          -- Hover and signature help
          -- Note: K is already mapped by default to vim.lsp.buf.hover()
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature help' }))
          
          -- Code actions and refactoring
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code action' }))
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
          
          -- Formatting
          vim.keymap.set('n', '<leader>f', function()
            vim.lsp.buf.format({ async = true })
          end, vim.tbl_extend('force', opts, { desc = 'Format document' }))
          
          -- Diagnostics navigation
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('force', opts, { desc = 'Go to previous diagnostic' }))
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('force', opts, { desc = 'Go to next diagnostic' }))
          vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = 'Show diagnostic' }))
          vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, vim.tbl_extend('force', opts, { desc = 'Open diagnostics list' }))
        end,
      })
      
      -- Configure diagnostic signs and display
      local signs = {
        { name = "DiagnosticSignError", text = "✘" },
        { name = "DiagnosticSignWarn", text = "▲" },
        { name = "DiagnosticSignHint", text = "⚑" },
        { name = "DiagnosticSignInfo", text = "»" },
      }
      
      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
      end
      
      -- Configure diagnostic display
      vim.diagnostic.config({
        virtual_text = {
          prefix = '●',
          spacing = 4,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = 'rounded',
          source = 'always',
          header = '',
          prefix = '',
        },
      })
      
      -- Configure floating windows
      local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = opts.border or 'rounded'
        return orig_util_open_floating_preview(contents, syntax, opts, ...)
      end
      
      -- Configure ts_ls (TypeScript/JavaScript language server)
      vim.lsp.config('ts_ls', {
        cmd = { 'typescript-language-server', '--stdio' },
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
        root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayVariableTypeHintsWhenTypeMatchesName = false,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayVariableTypeHintsWhenTypeMatchesName = false,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      })
      
      -- Enable ts_ls
      vim.lsp.enable('ts_ls')
    end,
  },

  -- ===================================================
  -- Formatting Plugins
  -- ===================================================

  -- conform.nvim: Advanced code formatting
  {
    "stevearc/conform.nvim",
    lazy = false,
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          markdown = { "prettier" },
          python = { "black", "isort" },
          go = { "gofmt", "goimports" },
          rust = { "rustfmt" },
          yaml = { "prettier" },
          toml = { "taplo" },
          sh = { "shfmt" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
        formatters = {
          prettier = {
            prepend_args = { "--print-width", "80", "--tab-width", "2" },
          },
          black = {
            prepend_args = { "--line-length", "80" },
          },
          stylua = {
            prepend_args = { "--column-width", "80" },
          },
        },
      })
    end,
  },

  -- ===================================================
  -- Completion Plugins
  -- ===================================================

  -- LuaSnip: Snippet engine
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- friendly-snippets: Collection of useful snippets
  {
    "rafamadriz/friendly-snippets",
  },

  -- nvim-cmp: Completion engine
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-y>"] = cmp.mapping.complete(), -- Alternative to <C-Space> for terminal compatibility
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        formatting = {
          format = function(entry, vim_item)
            -- Add source name to completion items
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
      })
    end,
  },

  -- cmp-nvim-lsp: LSP completion source
  {
    "hrsh7th/cmp-nvim-lsp",
  },

  -- cmp-buffer: Buffer text completion source
  {
    "hrsh7th/cmp-buffer",
  },

  -- cmp-path: File path completion source
  {
    "hrsh7th/cmp-path",
  },

  -- cmp_luasnip: LuaSnip completion source
  {
    "saadparwaiz1/cmp_luasnip",
  },

  -- nvim-autopairs: Auto close brackets, quotes, etc.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({
        check_ts = true, -- Enable treesitter integration
        ts_config = {
          lua = { "string" }, -- Don't add pairs in lua string treesitter nodes
          javascript = { "template_string" }, -- Don't add pairs in JS template strings
          java = false, -- Don't check treesitter on java
        },
      })

      -- Integrate with nvim-cmp
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
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
