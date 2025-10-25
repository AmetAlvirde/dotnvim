# LazyVim Configuration

This is a LazyVim-based Neovim configuration. LazyVim is a modern Neovim distribution that uses lazy.nvim as its plugin manager.

## What's Included

- **LazyVim**: A modern Neovim distribution with sensible defaults
- **Lazy.nvim**: Fast and modern plugin manager
- **Pre-configured plugins**: Includes popular plugins for development
- **Sensible keymaps**: Optimized keybindings for productivity
- **Auto-formatting**: Code formatting on save
- **LSP support**: Language Server Protocol integration
- **Tree-sitter**: Syntax highlighting and parsing

## Directory Structure

```
~/.config/nvim/
├── init.lua                 # Entry point
├── lua/
│   ├── config/
│   │   ├── lazy.lua        # LazyVim bootstrap
│   │   ├── options.lua     # Neovim options
│   │   ├── keymaps.lua     # Key mappings
│   │   └── autocmds.lua    # Auto commands
│   └── plugins/
│       └── init.lua        # Your custom plugins
```

## Getting Started

1. **First Launch**: When you first open Neovim, LazyVim will automatically:

   - Clone LazyVim repository
   - Install lazy.nvim plugin manager
   - Install all default plugins
   - Set up the configuration

2. **Plugin Management**:

   - Add plugins in `lua/plugins/` directory
   - Use `:Lazy` to open the plugin manager
   - Use `:Lazy sync` to install/update plugins

3. **Key Mappings**:
   - `<leader>` is mapped to `<space>` by default
   - Use `:help lazyvim-keymaps` for a full list

## Customization

- **Add plugins**: Create new files in `lua/plugins/` directory
- **Modify options**: Edit `lua/config/options.lua`
- **Add keymaps**: Edit `lua/config/keymaps.lua`
- **Custom autocmds**: Edit `lua/config/autocmds.lua`

## Useful Commands

- `:Lazy` - Open plugin manager
- `:Lazy sync` - Install/update plugins
- `:Lazy clean` - Remove unused plugins
- `:checkhealth` - Check Neovim health
- `:LazyVim` - LazyVim help

## Next Steps

1. Launch Neovim to let LazyVim set up automatically
2. Explore the default plugins and keymaps
3. Add your own plugins in `lua/plugins/`
4. Customize the configuration to your needs

For more information, visit [LazyVim Documentation](https://lazyvim.github.io/).
