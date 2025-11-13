# DotNVim

A modern Neovim configuration built from scratch, designed for web development
and note-taking workflows with a focus on developer experience and productivity.

## Overview

This is a comprehensive Neovim configuration that provides a complete
development environment with:

- **Modern Package Management**: Lazy.nvim for efficient plugin loading
- **Seamless Tmux Integration**: Navigate between tmux panes and vim windows effortlessly
- **Custom Solarized Theme**: Beautiful light/dark theme with automatic OS detection
- **Web Development Focus**: Optimized for React, Lit, web components, and modern frameworks
- **Obsidian Integration**: Complete note-taking workflow with custom templates
- **IntelliSense-like Experience**: Full LSP support with TypeScript/JavaScript
- **Git Integration**: Comprehensive git workflow with multiple tools
- **Developer Experience**: Carefully tuned settings, autopairs, rainbow delimiters, etc.

## Key Features

### Custom Solarized Theme

- **Automatic Theme Switching**: Detects macOS system preferences and switches between light/dark modes
- **Custom Implementation**: Built from scratch with proper Solarized color palette
- **Dynamic Statusline**: Lualine automatically adapts to theme changes
- **Manual Controls**: Quick toggle with `<leader>tt` or specific theme commands

### Web Development Excellence

- **Enhanced Syntax Highlighting**:
  - HTML and CSS syntax highlighting inside JavaScript template literals
  - JSX/TSX support with proper React highlighting
  - Lit element and web component support
- **Emmet Integration**: Full Emmet support inside HTML tagged templates
- **TypeScript/JavaScript LSP**: Complete language server with inlay hints
- **Code Formatting**: Prettier integration with format-on-save

### Obsidian Integration

- **Workspace Management**: Seamless integration with Obsidian vaults
- **Custom Note Templates**: Automatic frontmatter generation with timestamps
- **Link Navigation**: Follow and create Obsidian links
- **Search Integration**: Full-text search within your vault

### Navigation & Search

- **Telescope**: Fuzzy finding with FZF native performance
- **Neo-tree**: Modern file explorer sidebar
- **Buffer Management**: Quick switching between recent files
- **Git Navigation**: Seamless git history and diff viewing

### Developer Experience

- **Tmux Integration**: Navigate between tmux panes and vim windows with `<C-hjkl>`
- **Auto-pairs**: Smart bracket and quote completion
- **Rainbow Delimiters**: Color-coded brackets and parentheses
- **Persistent Undo**: Never lose your changes
- **Auto-formatting**: Format code on save for multiple languages

## Core Plugins

### Language Support

- **LSP**: Mason + nvim-lspconfig with TypeScript/JavaScript server
- **Completion**: nvim-cmp with LSP, snippets, and buffer completion
- **Snippets**: LuaSnip with friendly-snippets collection
- **Formatting**: Conform.nvim with multi-language formatter support

### Git Integration

- **LazyGit**: Terminal UI for git operations
- **GitSigns**: Inline git indicators and blame
- **Fugitive**: Full git integration
- **Diffview**: Split diffs and file history visualization

### Syntax & Highlighting

- **Treesitter**: Advanced syntax highlighting for 30+ languages
- **Rainbow Delimiters**: Color-coded brackets and parentheses
- **Template Literals**: Custom highlighting for HTML/CSS in JS template strings

### UI & Experience

- **Lualine**: Custom Solarized-themed statusline
- **Auto-pairs**: Smart bracket/quote completion
- **Tmux Navigator**: Seamless tmux integration

## Installation

### Prerequisites

- Neovim 0.11.0 or higher
- Git
- Node.js (for formatters like Prettier)
- Tmux (for tmux integration)

### Setup

1. Clone this repository to your Neovim config directory:

   ```bash
   git clone <your-repo-url> ~/.config/nvim
   ```

2. Start Neovim - Lazy.nvim will automatically install all plugins:

   ```bash
   nvim
   ```

3. Wait for the installation to complete (first launch may take a few minutes)

4. Restart Neovim to ensure everything loads properly

### Obsidian Setup

1. Update the workspace path in `lua/plugins/init.lua`:

   ```lua
   workspaces = {
     {
       name = "your-vault-name",
       path = "/path/to/your/obsidian/vault",
     },
   },
   ```

2. Use `<leader>oc` to enter your Obsidian workspace

## Configuration Structure

```
~/.config/nvim/
├── init.lua                 # Main entry point
├── version.lua              # Version information
├── lua/
│   ├── config/
│   │   ├── options.lua      # Neovim options
│   │   ├── keymaps.lua      # Key mappings
│   │   ├── autocmds.lua     # Auto-commands
│   │   └── template_literals.lua # Custom syntax
│   ├── plugins/
│   │   └── init.lua         # Plugin configurations
│   └── colors/
│       └── solarized.lua    # Custom Solarized theme
└── colors/
    └── solarized.lua        # Theme fallback
```

## Requirements

- **Neovim**: 0.11.0+
- **Git**: For plugin management
- **Node.js**: For formatters (Prettier, etc.)
- **Tmux**: For tmux integration (optional)
- **macOS/Linux**: For automatic theme detection

## Contributing

This is a personal configuration, but suggestions and improvements are welcome!
Feel free to:

- Report issues
- Suggest new features
- Share your own customizations

## License

This project is licensed under the MIT License - see the LICENSE file for details.
