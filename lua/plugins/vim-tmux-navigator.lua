-- vim-tmux-navigator: Seamless navigation between tmux panes and vim windows
return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  config = function()
    -- This plugin automatically handles the keymaps
    -- It will navigate within vim windows, and pass through to tmux when at boundaries
  end,
}

