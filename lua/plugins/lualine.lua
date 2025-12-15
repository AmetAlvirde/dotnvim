-- lualine.nvim: Statusline plugin with custom Solarized theme
return {
  "nvim-lualine/lualine.nvim",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- Import your custom Solarized colors
    local solarized_colors = require("colors.solarized")
    
    -- Function to get current theme colors
    local function get_colors()
      local theme = vim.o.background == "dark" and "dark" or "light"
      if theme == "dark" then
        return {
          bg0 = "#002d38",  -- base03
          bg1 = "#093946",  -- base02
          bg2 = "#5b7279",  -- base01
          fg0 = "#98a8a8",  -- base0
          fg1 = "#8faaab",  -- base1
          fg2 = "#657377",  -- base00
          fg3 = "#5b7279",  -- base01
          yellow = "#ac8300",
          orange = "#d56500",
          red = "#f23749",
          magenta = "#dd459d",
          violet = "#7d80d1",
          blue = "#2b90d8",
          cyan = "#259d94",
          green = "#819500",
        }
      else
        return {
          bg0 = "#fbf7ef",  -- base3
          bg1 = "#f1e9d2",  -- base2
          bg2 = "#8faaab",  -- base1
          fg0 = "#657377",  -- base00
          fg1 = "#5b7279",  -- base01
          fg2 = "#093946",  -- base02
          fg3 = "#002d38",  -- base03
          yellow = "#ac8300",
          orange = "#d56500",
          red = "#f23749",
          magenta = "#dd459d",
          violet = "#7d80d1",
          blue = "#2b90d8",
          cyan = "#259d94",
          green = "#819500",
        }
      end
    end

    -- Custom Solarized theme for lualine
    local function create_solarized_theme()
      local c = get_colors()
      return {
        normal = {
          a = { fg = c.bg0, bg = c.blue, gui = 'bold' },
          b = { fg = c.fg0, bg = c.bg1 },
          c = { fg = c.fg0, bg = c.bg0 },
        },
        insert = {
          a = { fg = c.bg0, bg = c.green, gui = 'bold' },
          b = { fg = c.fg0, bg = c.bg1 },
          c = { fg = c.fg0, bg = c.bg0 },
        },
        visual = {
          a = { fg = c.bg0, bg = c.magenta, gui = 'bold' },
          b = { fg = c.fg0, bg = c.bg1 },
          c = { fg = c.fg0, bg = c.bg0 },
        },
        replace = {
          a = { fg = c.bg0, bg = c.red, gui = 'bold' },
          b = { fg = c.fg0, bg = c.bg1 },
          c = { fg = c.fg0, bg = c.bg0 },
        },
        command = {
          a = { fg = c.bg0, bg = c.yellow, gui = 'bold' },
          b = { fg = c.fg0, bg = c.bg1 },
          c = { fg = c.fg0, bg = c.bg0 },
        },
        terminal = {
          a = { fg = c.bg0, bg = c.cyan, gui = 'bold' },
          b = { fg = c.fg0, bg = c.bg1 },
          c = { fg = c.fg0, bg = c.bg0 },
        },
        inactive = {
          a = { fg = c.fg2, bg = c.bg1 },
          b = { fg = c.fg2, bg = c.bg1 },
          c = { fg = c.fg2, bg = c.bg0 },
        },
      }
    end

    -- Function to setup lualine with current theme
    local function setup_lualine()
      require("lualine").setup({
        options = {
          theme = create_solarized_theme(),
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          }
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {
            {
              'filename',
              path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
              shorting_target = 40,
              symbols = {
                modified = ' ●',
                readonly = ' 🔒',
                unnamed = ' [No Name]',
                newfile = ' [New]',
              }
            }
          },
          lualine_x = {
            {
              'encoding',
              cond = function()
                return vim.bo.fileencoding ~= 'utf-8'
              end
            },
            {
              'fileformat',
              symbols = {
                unix = 'LF',
                dos = 'CRLF',
                mac = 'CR',
              }
            },
            'filetype'
          },
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      })
    end

    -- Initial setup
    setup_lualine()

    -- Create autocmd to refresh lualine when background changes
    vim.api.nvim_create_autocmd('OptionSet', {
      pattern = 'background',
      callback = function()
        -- print("Background option changed to:", vim.o.background)
        -- Small delay to ensure colorscheme is fully applied
        vim.defer_fn(function()
          setup_lualine()
          -- Force a redraw to ensure the statusline updates
          vim.cmd("redrawstatus")
          -- print("Lualine refreshed automatically!")
        end, 100)
      end,
      desc = 'Refresh lualine theme when background changes'
    })

    -- Alternative: Create autocmd for ColorScheme event
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = function()
        print("ColorScheme changed to:", vim.g.colors_name)
        vim.defer_fn(function()
          setup_lualine()
          vim.cmd("redrawstatus")
          -- print("Lualine refreshed via ColorScheme event!")
        end, 100)
      end,
      desc = 'Refresh lualine theme when colorscheme changes'
    })

    -- Also create a custom command to manually refresh lualine
    vim.api.nvim_create_user_command('LualineRefresh', function()
      setup_lualine()
      vim.cmd("redrawstatus")
      -- print("Lualine theme refreshed!")
    end, { desc = 'Manually refresh lualine theme' })

    -- Store the last known background for change detection
    local last_background = vim.o.background
    
    -- Create a timer to periodically check for background changes
    local background_check_timer = vim.loop.new_timer()
    background_check_timer:start(1000, 1000, function()
      vim.schedule(function()
        if vim.o.background ~= last_background then
          last_background = vim.o.background
          -- print("Detected background change to:", vim.o.background)
          setup_lualine()
          vim.cmd("redrawstatus")
          -- print("Lualine refreshed via timer!")
        end
      end)
    end)
  end,
}

