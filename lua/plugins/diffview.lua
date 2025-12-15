-- diffview.nvim: Split diffs and history views
return {
  "sindrets/diffview.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("diffview").setup({
      diff_binaries = false,    -- Show diffs for binaries
      enhanced_diff_hl = false, -- See ':h diffview-config-enhanced_diff_hl'
      git_cmd = { "git" },      -- The git executable followed by default args.
      use_icons = true,         -- Requires nvim-web-devicons
      show_help_hints = true,   -- Show hints for how to open the help panel
      watch_index = true,       -- Update views and index buffers when the git index changes.
      icons = {                 -- Only applies when use_icons is true.
        folder_closed = "",
        folder_open = "",
      },
      signs = {
        fold_closed = "",
        fold_open = "",
        done = "✓",
      },
      view = {
        default = {
          layout = "diff2_horizontal",
        },
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
        },
        file_history = {
          layout = "diff2_horizontal",
        },
      },
      file_panel = {
        listing_style = "tree",             -- One of 'list' or 'tree'
        tree_options = {
          flatten_dirs = true,              -- Flatten dirs that only contain one single dir
          folder_statuses = "only_folded",  -- One of 'never', 'only_folded' or 'always'.
        },
        win_config = {
          position = "left",                -- One of 'left', 'right', 'top', 'bottom'
          width = 35,                       -- Only applies when position is 'left' or 'right'
        },
      },
      file_history_panel = {
        log_options = {
          git = {
            single_file = {
              diff_merges = "combined",
            },
            multi_file = {
              diff_merges = "first-parent",
            },
          },
        },
        win_config = {
          position = "bottom",
          height = 16,
        },
      },
      commit_log_panel = {
        win_config = {},
      },
      default_args = {
        DiffviewOpen = {},
        DiffviewFileHistory = {},
      },
      hooks = {},                 -- See ':h diffview-config-hooks'
      keymaps = {
        disable_defaults = false, -- Disable the default keymaps
        view = {
          -- The `view` bindings are active in the diff buffers, only when the current
          -- tabpage is a Diffview.
          { "n", "<tab>",      "<cmd>lua require('diffview.actions').select_next_entry()<CR>",        { desc = "Open the diff for the next file" } },
          { "n", "<s-tab>",    "<cmd>lua require('diffview.actions').select_prev_entry()<CR>",        { desc = "Open the diff for the previous file" } },
          { "n", "gf",         "<cmd>lua require('diffview.actions').goto_file()<CR>",                { desc = "Open the file in a new split in the previous tabpage" } },
          { "n", "<C-w><C-f>", "<cmd>lua require('diffview.actions').goto_file_split()<CR>",          { desc = "Open the file in a new split" } },
          { "n", "<C-w>gf",    "<cmd>lua require('diffview.actions').goto_file_tab()<CR>",            { desc = "Open the file in a new tabpage" } },
          { "n", "<leader>e",  "<cmd>lua require('diffview.actions').focus_files()<CR>",              { desc = "Bring focus to the file panel" } },
          { "n", "<leader>b",  "<cmd>lua require('diffview.actions').toggle_files()<CR>",             { desc = "Toggle the file panel." } },
          { "n", "g<C-x>",     "<cmd>lua require('diffview.actions').cycle_layout()<CR>",             { desc = "Cycle through available layouts." } },
          { "n", "[x",         "<cmd>lua require('diffview.actions').prev_conflict()<CR>",            { desc = "In the merge_tool: jump to the previous conflict" } },
          { "n", "]x",         "<cmd>lua require('diffview.actions').next_conflict()<CR>",            { desc = "In the merge_tool: jump to the next conflict" } },
          { "n", "<leader>co", "<cmd>lua require('diffview.actions').conflict_choose('ours')<CR>",    { desc = "Choose the OURS version of a conflict" } },
          { "n", "<leader>ct", "<cmd>lua require('diffview.actions').conflict_choose('theirs')<CR>",  { desc = "Choose the THEIRS version of a conflict" } },
          { "n", "<leader>cb", "<cmd>lua require('diffview.actions').conflict_choose('base')<CR>",    { desc = "Choose the BASE version of a conflict" } },
          { "n", "<leader>ca", "<cmd>lua require('diffview.actions').conflict_choose('all')<CR>",     { desc = "Choose all the versions of a conflict" } },
          { "n", "dx",         "<cmd>lua require('diffview.actions').conflict_choose('none')<CR>",    { desc = "Delete the conflict region" } },
        },
        diff1 = {
          -- Mappings in single window diff layouts
          { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff1' })<CR>", { desc = "Open the help panel" } },
        },
        diff2 = {
          -- Mappings in 2-way diff layouts
          { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff2' })<CR>", { desc = "Open the help panel" } },
        },
        diff3 = {
          -- Mappings in 3-way diff layouts
          { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff3' })<CR>", { desc = "Open the help panel" } },
        },
        diff4 = {
          -- Mappings in 4-way diff layouts
          { "n", "g?", "<cmd>lua require('diffview.actions').help({ 'view', 'diff4' })<CR>", { desc = "Open the help panel" } },
        },
        file_panel = {
          { "n", "j",              "<cmd>lua require('diffview.actions').next_entry()<CR>",           { desc = "Bring the cursor to the next file entry" } },
          { "n", "<down>",         "<cmd>lua require('diffview.actions').next_entry()<CR>",           { desc = "Bring the cursor to the next file entry" } },
          { "n", "k",              "<cmd>lua require('diffview.actions').prev_entry()<CR>",           { desc = "Bring the cursor to the previous file entry." } },
          { "n", "<up>",           "<cmd>lua require('diffview.actions').prev_entry()<CR>",           { desc = "Bring the cursor to the previous file entry." } },
          { "n", "<cr>",           "<cmd>lua require('diffview.actions').select_entry()<CR>",         { desc = "Open the diff for the selected entry." } },
          { "n", "o",              "<cmd>lua require('diffview.actions').select_entry()<CR>",         { desc = "Open the diff for the selected entry." } },
          { "n", "<2-LeftMouse>",  "<cmd>lua require('diffview.actions').select_entry()<CR>",         { desc = "Open the diff for the selected entry." } },
          { "n", "-",              "<cmd>lua require('diffview.actions').toggle_stage_entry()<CR>",   { desc = "Stage / unstage the selected entry." } },
          { "n", "S",              "<cmd>lua require('diffview.actions').stage_all()<CR>",            { desc = "Stage all entries." } },
          { "n", "U",              "<cmd>lua require('diffview.actions').unstage_all()<CR>",          { desc = "Unstage all entries." } },
          { "n", "X",              "<cmd>lua require('diffview.actions').restore_entry()<CR>",        { desc = "Restore entry to the state on the left side." } },
          { "n", "L",              "<cmd>lua require('diffview.actions').open_commit_log()<CR>",      { desc = "Open the commit log panel." } },
          { "n", "<c-b>",          "<cmd>lua require('diffview.actions').scroll_view(-0.25)<CR>",     { desc = "Scroll the view up" } },
          { "n", "<c-f>",          "<cmd>lua require('diffview.actions').scroll_view(0.25)<CR>",      { desc = "Scroll the view down" } },
          { "n", "<tab>",          "<cmd>lua require('diffview.actions').select_next_entry()<CR>",    { desc = "Open the diff for the next file" } },
          { "n", "<s-tab>",        "<cmd>lua require('diffview.actions').select_prev_entry()<CR>",    { desc = "Open the diff for the previous file" } },
          { "n", "gf",             "<cmd>lua require('diffview.actions').goto_file()<CR>",            { desc = "Open the file in a new split in the previous tabpage" } },
          { "n", "<C-w><C-f>",     "<cmd>lua require('diffview.actions').goto_file_split()<CR>",      { desc = "Open the file in a new split" } },
          { "n", "<C-w>gf",        "<cmd>lua require('diffview.actions').goto_file_tab()<CR>",        { desc = "Open the file in a new tabpage" } },
          { "n", "i",              "<cmd>lua require('diffview.actions').listing_style()<CR>",        { desc = "Toggle between 'list' and 'tree' views" } },
          { "n", "f",              "<cmd>lua require('diffview.actions').toggle_flatten_dirs()<CR>",  { desc = "Flatten empty subdirectories in tree listing style." } },
          { "n", "R",              "<cmd>lua require('diffview.actions').refresh_files()<CR>",        { desc = "Update stats and entries in the file list." } },
          { "n", "<leader>e",      "<cmd>lua require('diffview.actions').focus_files()<CR>",          { desc = "Bring focus to the file panel" } },
          { "n", "<leader>b",      "<cmd>lua require('diffview.actions').toggle_files()<CR>",         { desc = "Toggle the file panel" } },
          { "n", "g<C-x>",         "<cmd>lua require('diffview.actions').cycle_layout()<CR>",         { desc = "Cycle available layouts" } },
          { "n", "[x",             "<cmd>lua require('diffview.actions').prev_conflict()<CR>",        { desc = "Go to the previous conflict" } },
          { "n", "]x",             "<cmd>lua require('diffview.actions').next_conflict()<CR>",        { desc = "Go to the next conflict" } },
          { "n", "g?",             "<cmd>lua require('diffview.actions').help('file_panel')<CR>",     { desc = "Open the help panel" } },
        },
        file_history_panel = {
          { "n", "g!",            "<cmd>lua require('diffview.actions').options()<CR>",               { desc = "Open the option panel" } },
          { "n", "<C-A-d>",       "<cmd>lua require('diffview.actions').open_in_diffview()<CR>",      { desc = "Open the entry under the cursor in a diffview" } },
          { "n", "y",             "<cmd>lua require('diffview.actions').copy_hash()<CR>",             { desc = "Copy the commit hash of the entry under the cursor" } },
          { "n", "L",             "<cmd>lua require('diffview.actions').open_commit_log()<CR>",       { desc = "Show commit details" } },
          { "n", "zR",            "<cmd>lua require('diffview.actions').open_all_folds()<CR>",        { desc = "Expand all folds" } },
          { "n", "zM",            "<cmd>lua require('diffview.actions').close_all_folds()<CR>",       { desc = "Collapse all folds" } },
          { "n", "j",             "<cmd>lua require('diffview.actions').next_entry()<CR>",            { desc = "Bring the cursor to the next file entry" } },
          { "n", "<down>",        "<cmd>lua require('diffview.actions').next_entry()<CR>",            { desc = "Bring the cursor to the next file entry" } },
          { "n", "k",             "<cmd>lua require('diffview.actions').prev_entry()<CR>",            { desc = "Bring the cursor to the previous file entry." } },
          { "n", "<up>",          "<cmd>lua require('diffview.actions').prev_entry()<CR>",            { desc = "Bring the cursor to the previous file entry." } },
          { "n", "<cr>",          "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Open the diff for the selected entry." } },
          { "n", "o",             "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Open the diff for the selected entry." } },
          { "n", "<2-LeftMouse>", "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Open the diff for the selected entry." } },
          { "n", "<c-b>",         "<cmd>lua require('diffview.actions').scroll_view(-0.25)<CR>",      { desc = "Scroll the view up" } },
          { "n", "<c-f>",         "<cmd>lua require('diffview.actions').scroll_view(0.25)<CR>",       { desc = "Scroll the view down" } },
          { "n", "<tab>",         "<cmd>lua require('diffview.actions').select_next_entry()<CR>",     { desc = "Open the diff for the next file" } },
          { "n", "<s-tab>",       "<cmd>lua require('diffview.actions').select_prev_entry()<CR>",     { desc = "Open the diff for the previous file" } },
          { "n", "gf",            "<cmd>lua require('diffview.actions').goto_file()<CR>",             { desc = "Open the file in a new split in the previous tabpage" } },
          { "n", "<C-w><C-f>",    "<cmd>lua require('diffview.actions').goto_file_split()<CR>",       { desc = "Open the file in a new split" } },
          { "n", "<C-w>gf",       "<cmd>lua require('diffview.actions').goto_file_tab()<CR>",         { desc = "Open the file in a new tabpage" } },
          { "n", "<leader>e",     "<cmd>lua require('diffview.actions').focus_files()<CR>",           { desc = "Bring focus to the file panel" } },
          { "n", "<leader>b",     "<cmd>lua require('diffview.actions').toggle_files()<CR>",          { desc = "Toggle the file panel" } },
          { "n", "g<C-x>",        "<cmd>lua require('diffview.actions').cycle_layout()<CR>",          { desc = "Cycle available layouts" } },
          { "n", "g?",            "<cmd>lua require('diffview.actions').help('file_history_panel')<CR>", { desc = "Open the help panel" } },
        },
        option_panel = {
          { "n", "<tab>", "<cmd>lua require('diffview.actions').select_entry()<CR>",          { desc = "Change the current option" } },
          { "n", "q",     "<cmd>lua require('diffview.actions').close()<CR>",                 { desc = "Close the panel" } },
          { "n", "g?",    "<cmd>lua require('diffview.actions').help('option_panel')<CR>",    { desc = "Open the help panel" } },
        },
        help_panel = {
          { "n", "q",     "<cmd>lua require('diffview.actions').close()<CR>",  { desc = "Close help menu" } },
          { "n", "<esc>", "<cmd>lua require('diffview.actions').close()<CR>",  { desc = "Close help menu" } },
        },
      },
    })

    -- Keymaps for Diffview commands
    vim.keymap.set('n', '<leader>dv', ':DiffviewOpen<CR>', { desc = 'Open Diffview' })
    vim.keymap.set('n', '<leader>dc', ':DiffviewClose<CR>', { desc = 'Close Diffview' })
    vim.keymap.set('n', '<leader>dh', ':DiffviewFileHistory<CR>', { desc = 'File history' })
    vim.keymap.set('n', '<leader>df', ':DiffviewFileHistory %<CR>', { desc = 'Current file history' })
    vim.keymap.set('n', '<leader>dr', ':DiffviewRefresh<CR>', { desc = 'Refresh Diffview' })
  end,
}

