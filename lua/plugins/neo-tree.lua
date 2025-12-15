-- neo-tree: Modern file explorer (similar to VSCode)
return {
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
}

