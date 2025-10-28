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
  -- Treesitter Plugin (Required for rainbow brackets)
  -- ===================================================

  -- nvim-treesitter: Syntax highlighting and parsing
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Install parsers for common languages
        ensure_installed = {
          "lua",
          "vim",
          "bash",
          "javascript",
          "typescript",
          "tsx",
          "json",
          "html",
          "css",
          "scss",
          "python",
          "java",
          "c",
          "cpp",
          "rust",
          "go",
          "php",
          "ruby",
          "swift",
          "kotlin",
          "scala",
          "clojure",
          "haskell",
          "ocaml",
          "fsharp",
          "elixir",
          "erlang",
          "scheme",
          "racket",
          "yaml",
          "toml",
          "dockerfile",
          "markdown",
          "r",
          "julia",
          "matlab",
          "sql",
          "graphql",
          "vue",
          "svelte",
          "astro",
        },
        -- Enable syntax highlighting
        highlight = {
          enable = true,
        },
        -- Enable indentation
        indent = {
          enable = true,
        },
      })
    end,
  },

  -- ===================================================
  -- Rainbow Brackets Plugin
  -- ===================================================

  -- rainbow-delimiters: Rainbow parentheses and brackets using treesitter
  {
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
  },

  -- ===================================================
  -- Git Integration Plugins
  -- ===================================================

  -- lazygit.nvim: Terminal UI for git commands
  {
    "kdheepak/lazygit.nvim",
    lazy = false,
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })
      vim.keymap.set("n", "<leader>gf", ":LazyGitFilter<CR>", { desc = "Open LazyGit (filtered)" })
      vim.keymap.set("n", "<leader>gc", ":LazyGitConfig<CR>", { desc = "Open LazyGit config" })
      vim.keymap.set("n", "<leader>gF", ":LazyGitFilterCurrentFile<CR>", { desc = "Open LazyGit (current file)" })
    end,
  },

  -- gitsigns.nvim: Git signs/lines and integration (lightweight)
  {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = '│' },
          change       = { text = '│' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
        numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir = {
          follow_files = true
        },
        attach_to_untracked = true,
        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          delay = 1000,
          ignore_whitespace = false,
        },
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil, -- Use default
        max_file_length = 40000, -- Disable if file is longer than this (in lines of the length)
        preview_config = {
          -- Options passed to nvim_open_win
          border = 'rounded',
          style = 'minimal',
          relative = 'cursor',
          row = 0,
          col = 1
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, {expr=true, desc = 'Next hunk'})

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, {expr=true, desc = 'Previous hunk'})

          -- Actions
          map('n', '<leader>hs', gs.stage_hunk, { desc = 'Stage hunk' })
          map('n', '<leader>hr', gs.reset_hunk, { desc = 'Reset hunk' })
          map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Stage hunk' })
          map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Reset hunk' })
          map('n', '<leader>hS', gs.stage_buffer, { desc = 'Stage buffer' })
          map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
          map('n', '<leader>hR', gs.reset_buffer, { desc = 'Reset buffer' })
          map('n', '<leader>hp', gs.preview_hunk, { desc = 'Preview hunk' })
          map('n', '<leader>hb', function() gs.blame_line{full=true} end, { desc = 'Blame line' })
          map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'Toggle line blame' })
          map('n', '<leader>hd', gs.diffthis, { desc = 'Diff this' })
          map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = 'Diff this ~' })
          map('n', '<leader>td', gs.toggle_deleted, { desc = 'Toggle deleted' })

          -- Text object
          map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'Select hunk' })
        end
      })
    end,
  },

  -- fugitive: Full Git integration
  {
    "tpope/vim-fugitive",
    lazy = false,
    config = function()
      -- Keymaps for common Fugitive commands
      vim.keymap.set('n', '<leader>gs', ':Git<CR>', { desc = 'Git status' })
      vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', { desc = 'Git commit' })
      vim.keymap.set('n', '<leader>gp', ':Git push<CR>', { desc = 'Git push' })
      vim.keymap.set('n', '<leader>gl', ':Git pull<CR>', { desc = 'Git pull' })
      vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { desc = 'Git blame' })
      vim.keymap.set('n', '<leader>gd', ':Gdiffsplit<CR>', { desc = 'Git diff split' })
      vim.keymap.set('n', '<leader>gw', ':Gwrite<CR>', { desc = 'Git write (stage)' })
      vim.keymap.set('n', '<leader>gr', ':Gread<CR>', { desc = 'Git read (checkout)' })
    end,
  },

  -- diffview.nvim: Split diffs and history views
  {
    "sindrets/diffview.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("diffview").setup({
        diff_binaries = false,    -- Show diffs for binaries
        enhanced_diff_hl = false, -- See ':h diffview-config-enhanced_diff_hl'
        git_cmd = { "git" },      -- The git executable followed by default args.
        use_icons = true,         -- Requires nvim-web-devicons
        show_help_hints = true,   -- Show hints for how to open the help panel
        watch_index = true,       -- Update views and index buffers when the git index changes.
        icons = {                 -- Only applies when use_icons is true.
          folder_closed = "",
          folder_open = "",
        },
        signs = {
          fold_closed = "",
          fold_open = "",
          done = "✓",
        },
        view = {
          default = {
            layout = "diff2_horizontal",
          },
          merge_tool = {
            layout = "diff3_horizontal",
            disable_diagnostics = true,
          },
          file_history = {
            layout = "diff2_horizontal",
          },
        },
        file_panel = {
          listing_style = "tree",             -- One of 'list' or 'tree'
          tree_options = {
            flatten_dirs = true,              -- Flatten dirs that only contain one single dir
            folder_statuses = "only_folded",  -- One of 'never', 'only_folded' or 'always'.
          },
          win_config = {
            position = "left",                -- One of 'left', 'right', 'top', 'bottom'
            width = 35,                       -- Only applies when position is 'left' or 'right'
          },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                diff_merges = "combined",
              },
              multi_file = {
                diff_merges = "first-parent",
              },
            },
          },
          win_config = {
            position = "bottom",
            height = 16,
          },
        },
        commit_log_panel = {
          win_config = {},
        },
        default_args = {
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
        hooks = {},                 -- See ':h diffview-config-hooks'
        keymaps = {
          disable_defaults = false, -- Disable the default keymaps
          view = {
            -- The `view` bindings are active in the diff buffers, only when the current
            -- tabpage is a Diffview.
            { "n", "<tab>",      "<cmd>lua require('diffview.actions').select_next_entry()<CR>",        { desc = "Open the diff for the next file" } },
            { "n", "<s-tab>",    "<cmd>lua require('diffview.actions').select_prev_entry()<CR>",        { desc = "Open the diff for the previous file" } },
            { "n", "gf",         "<cmd>lua require('diffview.actions').goto_file()<CR>",                { desc = "Open the file in a new split in the previous tabpage" } },
            { "n", "<C-w><C-f>", "<cmd>lua require('diffview.actions').goto_file_split()<CR>",          { desc = "Open the file in a new split" } },
            { "n", "<C-w>gf",    "<cmd>lua require('diffview.actions').goto_file_tab()<CR>",            { desc = "Open the file in a new tabpage" } },
            { "n", "<leader>e",  "<cmd>lua require('diffview.actions').focus_files()<CR>",              { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b",  "<cmd>lua require('diffview.actions').toggle_files()<CR>",             { desc = "Toggle the file panel." } },
            { "n", "g<C-x>",     "<cmd>lua require('diffview.actions').cycle_layout()<CR>",             { desc = "Cycle through available layouts." } },
            { "n", "[x",         "<cmd>lua require('diffview.actions').prev_conflict()<CR>",            { desc = "In the merge_tool: jump to the previous conflict" } },
            { "n", "]x",         "<cmd>lua require('diffview.actions').next_conflict()<CR>",            { desc = "In the merge_tool: jump to the next conflict" } },
            { "n", "<leader>co", "<cmd>lua require('diffview.actions').conflict_choose('ours')<CR>",    { desc = "Choose the OURS version of a conflict" } },
            { "n", "<leader>ct", "<cmd>lua require('diffview.actions').conflict_choose('theirs')<CR>",  { desc = "Choose the THEIRS version of a conflict" } },
            { "n", "<leader>cb", "<cmd>lua require('diffview.actions').conflict_choose('base')<CR>",    { desc = "Choose the BASE version of a conflict" } },
            { "n", "<leader>ca", "<cmd>lua require('diffview.actions').conflict_choose('all')<CR>",     { desc = "Choose all the versions of a conflict" } },
            { "n", "dx",         "<cmd>lua require('diffview.actions').conflict_choose('none')<CR>",    { desc = "Delete the conflict region" } },
          },
          diff1 = {
            -- Mappings in single window diff layouts
            { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff1' })<CR>", { desc = "Open the help panel" } },
          },
          diff2 = {
            -- Mappings in 2-way diff layouts
            { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff2' })<CR>", { desc = "Open the help panel" } },
          },
          diff3 = {
            -- Mappings in 3-way diff layouts
            { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff3' })<CR>", { desc = "Open the help panel" } },
          },
          diff4 = {
            -- Mappings in 4-way diff layouts
            { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff4' })<CR>", { desc = "Open the help panel" } },
          },
          file_panel = {
            { "n", "j",              "<cmd>lua require('diffview.actions').next_entry()<CR>",           { desc = "Bring the cursor to the next file entry" } },
            { "n", "<down>",         "<cmd>lua require('diffview.actions').next_entry()<CR>",           { desc = "Bring the cursor to the next file entry" } },
            { "n", "k",              "<cmd>lua require('diffview.actions').prev_entry()<CR>",           { desc = "Bring the cursor to the previous file entry." } },
            { "n", "<up>",           "<cmd>lua require('diffview.actions').prev_entry()<CR>",           { desc = "Bring the cursor to the previous file entry." } },
            { "n", "<cr>",           "<cmd>lua require('diffview.actions').select_entry()<CR>",         { desc = "Open the diff for the selected entry." } },
            { "n", "o",              "<cmd>lua require('diffview.actions').select_entry()<CR>",         { desc = "Open the diff for the selected entry." } },
            { "n", "<2-LeftMouse>",  "<cmd>lua require('diffview.actions').select_entry()<CR>",         { desc = "Open the diff for the selected entry." } },
            { "n", "-",              "<cmd>lua require('diffview.actions').toggle_stage_entry()<CR>",   { desc = "Stage / unstage the selected entry." } },
            { "n", "S",              "<cmd>lua require('diffview.actions').stage_all()<CR>",            { desc = "Stage all entries." } },
            { "n", "U",              "<cmd>lua require('diffview.actions').unstage_all()<CR>",          { desc = "Unstage all entries." } },
            { "n", "X",              "<cmd>lua require('diffview.actions').restore_entry()<CR>",        { desc = "Restore entry to the state on the left side." } },
            { "n", "L",              "<cmd>lua require('diffview.actions').open_commit_log()<CR>",      { desc = "Open the commit log panel." } },
            { "n", "<c-b>",          "<cmd>lua require('diffview.actions').scroll_view(-0.25)<CR>",     { desc = "Scroll the view up" } },
            { "n", "<c-f>",          "<cmd>lua require('diffview.actions').scroll_view(0.25)<CR>",      { desc = "Scroll the view down" } },
            { "n", "<tab>",          "<cmd>lua require('diffview.actions').select_next_entry()<CR>",    { desc = "Open the diff for the next file" } },
            { "n", "<s-tab>",        "<cmd>lua require('diffview.actions').select_prev_entry()<CR>",    { desc = "Open the diff for the previous file" } },
            { "n", "gf",             "<cmd>lua require('diffview.actions').goto_file()<CR>",            { desc = "Open the file in a new split in the previous tabpage" } },
            { "n", "<C-w><C-f>",     "<cmd>lua require('diffview.actions').goto_file_split()<CR>",      { desc = "Open the file in a new split" } },
            { "n", "<C-w>gf",        "<cmd>lua require('diffview.actions').goto_file_tab()<CR>",        { desc = "Open the file in a new tabpage" } },
            { "n", "i",              "<cmd>lua require('diffview.actions').listing_style()<CR>",        { desc = "Toggle between 'list' and 'tree' views" } },
            { "n", "f",              "<cmd>lua require('diffview.actions').toggle_flatten_dirs()<CR>",  { desc = "Flatten empty subdirectories in tree listing style." } },
            { "n", "R",              "<cmd>lua require('diffview.actions').refresh_files()<CR>",        { desc = "Update stats and entries in the file list." } },
            { "n", "<leader>e",      "<cmd>lua require('diffview.actions').focus_files()<CR>",          { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b",      "<cmd>lua require('diffview.actions').toggle_files()<CR>",         { desc = "Toggle the file panel" } },
            { "n", "g<C-x>",         "<cmd>lua require('diffview.actions').cycle_layout()<CR>",         { desc = "Cycle available layouts" } },
            { "n", "[x",             "<cmd>lua require('diffview.actions').prev_conflict()<CR>",        { desc = "Go to the previous conflict" } },
            { "n", "]x",             "<cmd>lua require('diffview.actions').next_conflict()<CR>",        { desc = "Go to the next conflict" } },
            { "n", "g?",             "<cmd>lua require('diffview.actions').help('file_panel')<CR>",     { desc = "Open the help panel" } },
          },
          file_history_panel = {
            { "n", "g!",            "<cmd>lua require('diffview.actions').options()<CR>",               { desc = "Open the option panel" } },
            { "n", "<C-A-d>",       "<cmd>lua require('diffview.actions').open_in_diffview()<CR>",      { desc = "Open the entry under the cursor in a diffview" } },
            { "n", "y",             "<cmd>lua require('diffview.actions').copy_hash()<CR>",             { desc = "Copy the commit hash of the entry under the cursor" } },
            { "n", "L",             "<cmd>lua require('diffview.actions').open_commit_log()<CR>",       { desc = "Show commit details" } },
            { "n", "zR",            "<cmd>lua require('diffview.actions').open_all_folds()<CR>",        { desc = "Expand all folds" } },
            { "n", "zM",            "<cmd>lua require('diffview.actions').close_all_folds()<CR>",       { desc = "Collapse all folds" } },
            { "n", "j",             "<cmd>lua require('diffview.actions').next_entry()<CR>",            { desc = "Bring the cursor to the next file entry" } },
            { "n", "<down>",        "<cmd>lua require('diffview.actions').next_entry()<CR>",            { desc = "Bring the cursor to the next file entry" } },
            { "n", "k",             "<cmd>lua require('diffview.actions').prev_entry()<CR>",            { desc = "Bring the cursor to the previous file entry." } },
            { "n", "<up>",          "<cmd>lua require('diffview.actions').prev_entry()<CR>",            { desc = "Bring the cursor to the previous file entry." } },
            { "n", "<cr>",          "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Open the diff for the selected entry." } },
            { "n", "o",             "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Open the diff for the selected entry." } },
            { "n", "<2-LeftMouse>", "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Open the diff for the selected entry." } },
            { "n", "<c-b>",         "<cmd>lua require('diffview.actions').scroll_view(-0.25)<CR>",      { desc = "Scroll the view up" } },
            { "n", "<c-f>",         "<cmd>lua require('diffview.actions').scroll_view(0.25)<CR>",       { desc = "Scroll the view down" } },
            { "n", "<tab>",         "<cmd>lua require('diffview.actions').select_next_entry()<CR>",     { desc = "Open the diff for the next file" } },
            { "n", "<s-tab>",       "<cmd>lua require('diffview.actions').select_prev_entry()<CR>",     { desc = "Open the diff for the previous file" } },
            { "n", "gf",            "<cmd>lua require('diffview.actions').goto_file()<CR>",             { desc = "Open the file in a new split in the previous tabpage" } },
            { "n", "<C-w><C-f>",    "<cmd>lua require('diffview.actions').goto_file_split()<CR>",       { desc = "Open the file in a new split" } },
            { "n", "<C-w>gf",       "<cmd>lua require('diffview.actions').goto_file_tab()<CR>",         { desc = "Open the file in a new tabpage" } },
            { "n", "<leader>e",     "<cmd>lua require('diffview.actions').focus_files()<CR>",           { desc = "Bring focus to the file panel" } },
            { "n", "<leader>b",     "<cmd>lua require('diffview.actions').toggle_files()<CR>",          { desc = "Toggle the file panel" } },
            { "n", "g<C-x>",        "<cmd>lua require('diffview.actions').cycle_layout()<CR>",          { desc = "Cycle available layouts" } },
            { "n", "g?",            "<cmd>lua require('diffview.actions').help('file_history_panel')<CR>", { desc = "Open the help panel" } },
          },
          option_panel = {
            { "n", "<tab>", "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Change the current option" } },
            { "n", "q",     "<cmd>lua require('diffview.actions').close()<CR>",                 { desc = "Close the panel" } },
            { "n", "g?",    "<cmd>lua require('diffview.actions').help('option_panel')<CR>",    { desc = "Open the help panel" } },
          },
          help_panel = {
            { "n", "q",     "<cmd>lua require('diffview.actions').close()<CR>",  { desc = "Close help menu" } },
            { "n", "<esc>", "<cmd>lua require('diffview.actions').close()<CR>",  { desc = "Close help menu" } },
          },
        },
      })

      -- Keymaps for Diffview commands
      vim.keymap.set('n', '<leader>dv', ':DiffviewOpen<CR>', { desc = 'Open Diffview' })
      vim.keymap.set('n', '<leader>dc', ':DiffviewClose<CR>', { desc = 'Close Diffview' })
      vim.keymap.set('n', '<leader>dh', ':DiffviewFileHistory<CR>', { desc = 'File history' })
      vim.keymap.set('n', '<leader>df', ':DiffviewFileHistory %<CR>', { desc = 'Current file history' })
      vim.keymap.set('n', '<leader>dr', ':DiffviewRefresh<CR>', { desc = 'Refresh Diffview' })
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
