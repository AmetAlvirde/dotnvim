local opt = vim.opt

-- line numbers
-- opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = false

-- search settings
opt.ignorecase = true
opt.smartcase = true

-- cursor line
opt.cursorline = true

-- appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- colorscheme
vim.cmd("colorscheme solarized")

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
opt.clipboard:append("unnamedplus")

-- split windows
opt.splitright = true
opt.splitbelow = true

-- turn off swapfile
opt.swapfile = false
opt.backup = false
opt.undodir = vim.fn.stdpath("config") .. "/undodir"
opt.undofile = true

-- scrolloff
opt.scrolloff = 8

-- updatetime
opt.updatetime = 50

-- colorcolumn
opt.colorcolumn = "80"

-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "
