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
    --- Timezone suffix for frontmatter, e.g. "(GMT-6)" or "(GMT+5:30)".
    --- Uses strftime %z (RFC 822 style) so offset matches the system clock.
    local function get_tz_offset()
      local z = vim.fn.strftime("%z")
      if not z or #z < 5 then
        return "(GMT)"
      end
      local sign = z:sub(1, 1) == "-" and "-" or "+"
      local hh = tonumber(z:sub(2, 3), 10) or 0
      local mm = tonumber(z:sub(4, 5), 10) or 0
      if mm > 0 then
        return string.format("(GMT%s%d:%02d)", sign, hh, mm)
      end
      return string.format("(GMT%s%d)", sign, hh)
    end

    require("obsidian").setup({
      workspaces = {
        {
          name = "conscium",
          path = "/Users/amet/Writing/conscium",
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
      
      -- Custom ID generation function (filename stem; UTF-8 safe, no unix prefix)
      note_id_func = function(title)
        local suffix = ""
        if title ~= nil then
          -- Keep Unicode letters; strip only filesystem-unsafe chars; lowercase via Vim (UTF-8 aware).
          -- Parentheses: gsub returns (str, count); only the string must be passed to tolower.
          suffix = vim.fn.tolower((title:gsub("%s+", "-"):gsub('[/\\:*?"<>|]', "")))
        end
        if suffix == "" then
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return suffix
      end,
      
      -- Custom frontmatter template function
      note_frontmatter_func = function(note)
        if note.title then
          note:add_alias(note.title)
        end

        local tz = get_tz_offset()
        local now = os.date("%Y-%m-%d %H:%M:%S") .. " " .. tz

        local created = now
        if note.metadata and note.metadata.created then
          created = note.metadata.created
        end

        local out = {
          id = note.id,
          aliases = note.aliases,
          tags = note.tags,
          created = created,
          modified = now,
        }

        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            if k ~= "created" and k ~= "modified" then
              out[k] = v
            end
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

