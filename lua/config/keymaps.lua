local keymap = vim.keymap.set

-- Better indenting
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- vim-tmux-navigator plugin handles <C-hjkl> navigation
-- It automatically manages navigation between vim windows and tmux panes

-- Resize window using <ctrl> arrow keys
keymap("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
keymap("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Clear search with <esc>
keymap({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Clear search, diff update and redraw
keymap(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / clear hlsearch / diff update" }
)

-- Add undo break-points
keymap("i", ",", ",<c-g>u")
keymap("i", ".", ".<c-g>u")
keymap("i", ";", ";<c-g>u")

-- save file
keymap({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- QuickFix
keymap("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
keymap("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })

-- quit
keymap("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- windows
keymap("n", "<leader>ww", "<C-W>p", { desc = "Other window", remap = true })
keymap("n", "<leader>wd", "<C-W>c", { desc = "Delete window", remap = true })
keymap("n", "<leader>w-", "<C-W>s", { desc = "Split window below", remap = true })
keymap("n", "<leader>w|", "<C-W>v", { desc = "Split window right", remap = true })
keymap("n", "<leader>-", "<C-W>s", { desc = "Split window below", remap = true })
keymap("n", "<leader>|", "<C-W>v", { desc = "Split window right", remap = true })

-- tabs
keymap("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
keymap("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
keymap("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
keymap("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
keymap("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
keymap("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Solarized theme toggle
keymap("n", "<leader>tt", "<cmd>SolarizedToggle<cr>", { desc = "Toggle Solarized theme" })
keymap("n", "<leader>td", "<cmd>SolarizedDark<cr>", { desc = "Set Solarized dark" })
keymap("n", "<leader>tl", "<cmd>SolarizedLight<cr>", { desc = "Set Solarized light" })

-- Emmet keymaps
keymap("i", "<C-y>,", "<Plug>(emmet-expand-abbr)", { desc = "Expand Emmet abbreviation" })
keymap("i", "<C-y>;", "<Plug>(emmet-expand-word)", { desc = "Expand Emmet word" })
keymap("i", "<C-y>d", "<Plug>(emmet-balance-tag-inward)", { desc = "Balance tag inward" })
keymap("i", "<C-y>D", "<Plug>(emmet-balance-tag-outward)", { desc = "Balance tag outward" })
keymap("i", "<C-y>n", "<Plug>(emmet-move-next)", { desc = "Move to next edit point" })
keymap("i", "<C-y>N", "<Plug>(emmet-move-prev)", { desc = "Move to previous edit point" })
keymap("i", "<C-y>i", "<Plug>(emmet-image-size)", { desc = "Update image size" })
keymap("i", "<C-y>I", "<Plug>(emmet-image-encode)", { desc = "Encode image" })
keymap("i", "<C-y>j", "<Plug>(emmet-split-join-tag)", { desc = "Split/join tag" })
keymap("i", "<C-y>k", "<Plug>(emmet-remove-tag)", { desc = "Remove tag" })
keymap("i", "<C-y>/", "<Plug>(emmet-toggle-comment)", { desc = "Toggle comment" })
keymap("i", "<C-y>a", "<Plug>(emmet-anchorize-url)", { desc = "Anchorize URL" })
keymap("i", "<C-y>A", "<Plug>(emmet-anchorize-summary)", { desc = "Anchorize summary" })
keymap("i", "<C-y>m", "<Plug>(emmet-merge-lines)", { desc = "Merge lines" })
keymap("i", "<C-y>c", "<Plug>(emmet-code-pretty)", { desc = "Pretty code" })