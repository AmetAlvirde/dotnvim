-- Solarized colorscheme entry point
-- This file is required by Neovim's colorscheme system

local solarized = require("colors.solarized")

-- Set up the colorscheme
solarized.setup()

-- Export for external use
_G.solarized = solarized
