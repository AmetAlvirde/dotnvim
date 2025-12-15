-- telescope.nvim: Fuzzy finder
return {
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
}

