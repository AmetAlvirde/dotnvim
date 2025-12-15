local plugins = {}

-- Essential plugins (syntax highlighting, navigation)
table.insert(plugins, require("plugins.vim-tmux-navigator"))
table.insert(plugins, require("plugins.vim-html-template-literals"))
table.insert(plugins, require("plugins.vim-styled-components"))
table.insert(plugins, require("plugins.vim-javascript"))
table.insert(plugins, require("plugins.vim-jsx-pretty"))
table.insert(plugins, require("plugins.typescript-vim"))
table.insert(plugins, require("plugins.emmet-vim"))

-- File explorer plugins
table.insert(plugins, require("plugins.neo-tree"))

-- Telescope plugins
table.insert(plugins, require("plugins.telescope"))
table.insert(plugins, require("plugins.telescope-fzf-native"))

-- LSP plugins
table.insert(plugins, require("plugins.mason"))
table.insert(plugins, require("plugins.nvim-lspconfig"))

-- Formatting plugins
table.insert(plugins, require("plugins.conform"))

-- Completion plugins
table.insert(plugins, require("plugins.luasnip"))
table.insert(plugins, require("plugins.friendly-snippets"))
table.insert(plugins, require("plugins.nvim-cmp"))
table.insert(plugins, require("plugins.cmp-nvim-lsp"))
table.insert(plugins, require("plugins.cmp-buffer"))
table.insert(plugins, require("plugins.cmp-path"))
table.insert(plugins, require("plugins.cmp-luasnip"))
table.insert(plugins, require("plugins.nvim-autopairs"))

-- Treesitter plugins
table.insert(plugins, require("plugins.nvim-treesitter"))
table.insert(plugins, require("plugins.rainbow-delimiters"))

-- Git integration plugins
table.insert(plugins, require("plugins.lazygit"))
table.insert(plugins, require("plugins.gitsigns"))
table.insert(plugins, require("plugins.vim-fugitive"))
table.insert(plugins, require("plugins.diffview"))

-- Statusline plugin
table.insert(plugins, require("plugins.lualine"))

-- Writing and note taking plugins
table.insert(plugins, require("plugins.obsidian"))

return plugins

