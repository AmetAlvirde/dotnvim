-- Obsidian.nvim: Obsidian notes integration
return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = false,
  -- Remove ft = "markdown" to load globally, not just for markdown files
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("obsidian").setup({
      workspaces = {
        {
          name = "conscium",
          path = "/Users/amet/2025/conscium",
        },
        {
          name = "cronicasDeUnCorredorComoTu",
          path = "/Users/amet/2025/work/mycelium/cronicas-de-un-corredor-como-tu",
        },
      },
      
      -- Remove notes_subdir to keep notes in root
      -- notes_subdir = "notes",
      
      daily_notes = {
        folder = "daily",
        date_format = "%Y-%m-%d",
      },
      
      -- Custom ID generation function
      note_id_func = function(title)
        local suffix = ""
        if title ~= nil then
          -- Transform title into a valid file name.
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          -- If title is nil, add 4 random uppercase letters to the suffix.
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return tostring(os.time()) .. "-" .. suffix
      end,
      
      -- Custom frontmatter template function
      note_frontmatter_func = function(note)
        -- Add the title of the note as an alias.
        if note.title then
          note:add_alias(note.title)
        end

        local out = { 
          id = note.id, 
          aliases = note.aliases, 
          tags = note.tags,
          created = os.date("%Y-%m-%d %H:%M:%S"),
          modified = os.date("%Y-%m-%d %H:%M:%S")
        }

        -- Preserve any manually added fields in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
      
      -- Completion
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },
      
      -- Key mappings
      mappings = {
        -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- Toggle check-boxes.
        ["<leader>ch"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true },
        },
        
        -- Obsidian-specific keybindings are now handled in keymaps.lua
        -- This prevents conflicts and ensures they work globally
      },
    })
  
    -- Set conceallevel for Obsidian syntax features
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        vim.opt_local.conceallevel = 2
      end,
    })
    
  end,
}

