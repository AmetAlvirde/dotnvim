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
-- have to find better substitutes for these, they move the lines when I am on
-- insert mode and want to move to normal mode, that is something I do a lot.
-- keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
-- keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
-- keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
-- keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
-- keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
-- keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

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

-- force save file (overwrite external changes)
keymap({ "i", "v", "n", "s" }, "<C-S>", "<cmd>w!<cr><esc>", { desc = "Force save file" })

-- check if file was modified externally
keymap("n", "<leader>ct", "<cmd>checktime<cr>", { desc = "Check if file was modified externally" })

-- reload file from disk
keymap("n", "<leader>r", "<cmd>e!<cr>", { desc = "Reload file from disk" })

-- Solarized theme toggle
keymap("n", "<leader>tt", function()
  require("colors.solarized").toggle()
end, { desc = "Toggle Solarized theme (dark/light)" })

-- Manual lualine refresh (for debugging)
keymap("n", "<leader>tr", function()
  if vim.fn.exists(':LualineRefresh') == 2 then
    vim.cmd("LualineRefresh")
  else
    print("LualineRefresh command not available")
  end
end, { desc = "Refresh lualine theme manually" })

-- format file
keymap("n", "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file" })

-- format markdown with hard line breaks
keymap("n", "<leader>fm", function()
  if vim.bo.filetype == "markdown" then
    -- Format with Prettier for markdown with hard line breaks
    vim.cmd(":%!prettier --print-width 80 --prose-wrap always --tab-width 2 --stdin-filepath " .. vim.fn.expand("%"))
  else
    require("conform").format({ async = true, lsp_fallback = true })
  end
end, { desc = "Format markdown with hard line breaks" })

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

-- ===================================================
-- File Explorer Keymaps
-- ===================================================

-- Neo-tree toggle (right side)
keymap("n", "<leader>e", "<cmd>Neotree filesystem toggle right<cr>", { desc = "Toggle Neo-tree (right side)" })

-- Oil.nvim file explorer
-- keymap("n", "<leader>l", "<cmd>Oil<cr>", { desc = "Open Oil file explorer" })

-- ===================================================
-- Telescope Keymaps
-- ===================================================

-- Find files in current directory
keymap("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files in current directory" })

-- Find files in git project root
keymap("n", "<leader>fp", function()
  require("telescope.builtin").git_files()
end, { desc = "Find files in git project root" })

-- Find recent buffers with Telescope
keymap("n", "<leader>fr", function()
  require("telescope.builtin").buffers({
    sort_mru = true,
    ignore_current_buffer = true,
  })
end, { desc = "Find recent buffers" })

-- Go to last buffer (immediately switch to most recently used buffer)
keymap("n", "<leader>fl", function()
  -- Get all loaded buffers
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())
  
  -- Sort by most recently used (higher number = more recent)
  table.sort(buffers, function(a, b)
    return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
  end)
  
  -- Switch to the most recently used buffer (excluding current)
  for _, buf in ipairs(buffers) do
    if buf ~= vim.api.nvim_get_current_buf() then
      vim.api.nvim_set_current_buf(buf)
      break
    end
  end
end, { desc = "Go to last buffer" })

-- ===================================================
-- Obsidian Workspace Keymaps
-- ===================================================

-- Global function to enter Obsidian workspace
local function enter_obsidian_workspace(workspace_name)
  local workspaces = {
    conscium = "/Users/amet/2025/conscium",
    cronicasDeUnCorredorComoTu = "/Users/amet/2025/work/mycelium/cronicas-de-un-corredor-como-tu",
  }
  
  local path = workspaces[workspace_name]
  if not path then
    vim.notify("Unknown workspace: " .. (workspace_name or "nil"), vim.log.levels.ERROR)
    return
  end
  
  -- Switch Obsidian.nvim workspace
  local ok, obsidian = pcall(require, "obsidian")
  if ok then
    local client = obsidian.get_client()
    if client then
      client:switch_workspace(workspace_name)
    end
  end
  
  -- Change to the workspace directory
  vim.cmd('cd ' .. path)
  -- Open the workspace in Neo-tree (file explorer)
  -- vim.cmd('Neotree filesystem show right')
  vim.notify('Entered Obsidian workspace: ' .. workspace_name)
end

-- Global keybindings to enter Obsidian workspaces
keymap('n', '<leader>oc', function() enter_obsidian_workspace('conscium') end, { desc = 'Enter conscium workspace' })
-- keymap('n', '<leader>oa', function() enter_obsidian_workspace('AmetAlvirde') end, { desc = 'Enter AmetAlvirde workspace' })
keymap('n', '<leader>or', function() enter_obsidian_workspace('cronicasDeUnCorredorComoTu') end, { desc = 'Enter cronicasDeUnCorredorComoTu workspace' })

local function link_or_create_obsidian_note()
  local ok, obsidian = pcall(require, "obsidian")
  if not ok then
    vim.notify("obsidian.nvim is not available", vim.log.levels.ERROR)
    return
  end

  local client = obsidian.get_client()
  if not client then
    vim.notify("No active Obsidian workspace", vim.log.levels.WARN)
    return
  end

  local util_ok, util = pcall(require, "obsidian.util")
  if not util_ok then
    vim.notify("Failed to load obsidian.util", vim.log.levels.ERROR)
    return
  end

  local viz = util.get_visual_selection()
  if not viz or #viz.lines ~= 1 then
    vim.notify("Select inline text before linking", vim.log.levels.ERROR)
    return
  end

  local selection = viz.selection
  local line = assert(viz.lines[1])

  local function insert_link(note)
    if not note then
      vim.notify("No note provided to link", vim.log.levels.ERROR)
      return
    end
    local new_line = string.sub(line, 1, viz.cscol - 1)
      .. client:format_link(note, { label = selection })
      .. string.sub(line, viz.cecol + 1)

    vim.api.nvim_buf_set_lines(0, viz.csrow - 1, viz.csrow, false, { new_line })
    client:update_ui()
  end

  local function create_and_link_note(input_title)
    local title
    if type(input_title) == "string" then
      title = vim.trim(input_title)
      if title == "" then
        title = nil
      end
    end
    if not title then
      title = selection
    end
    local ok, note = pcall(client.create_note, client, { title = title })
    if not ok then
      vim.notify(string.format("Failed to create note for “%s”: %s", title, note), vim.log.levels.ERROR)
      return
    end
    if not note or not note.path then
      vim.notify(string.format("Note creation returned invalid result for “%s”", title), vim.log.levels.ERROR)
      return
    end
    if not note.path:is_file() then
      local write_ok, write_err = pcall(function()
        note = client:write_note(note)
      end)
      if not write_ok then
        vim.notify(string.format("Failed to write note for “%s”: %s", title, write_err), vim.log.levels.ERROR)
        return
      end
    end
    vim.notify(string.format("Linked to new note: %s", tostring(note.path)), vim.log.levels.INFO)
    insert_link(note)
  end

  client:resolve_note_async(selection, function(...)
    local notes = { ... }
    vim.schedule(function()
      if #notes == 0 then
        local picker = client:picker()
        if picker then
          local query_mappings = picker:_note_query_mappings() or {}
          query_mappings["<C-y>"] = {
            desc = "new note",
            callback = function(query)
              create_and_link_note(query)
            end,
          }

          local selection_mappings = picker:_note_selection_mappings() or {}
          selection_mappings["<C-y>"] = {
            desc = "new note",
            callback = function(...)
              create_and_link_note(...)
            end,
            fallback_to_query = true,
          }

          local query_mappings = picker._note_query_mappings and picker:_note_query_mappings() or {}
          query_mappings["<C-y>"] = {
            desc = "new note",
            callback = function(query)
              create_and_link_note(query)
            end,
          }

          local selection_mappings = picker._note_selection_mappings and picker:_note_selection_mappings() or {}
          selection_mappings["<C-y>"] = {
            desc = "new note",
            callback = function(...)
              create_and_link_note(...)
            end,
            fallback_to_query = true,
          }

          picker:find_notes({
            prompt_title = string.format("Link “%s” to…", selection),
            no_default_mappings = true,
            query_mappings = query_mappings,
            selection_mappings = selection_mappings,
            callback = function(path)
              if not path or path == "" then
                local choice = vim.fn.confirm(
                  string.format("Create new note for “%s”?", selection),
                  "&Create\n&Cancel",
                  1
                )
                if choice == 1 then
                  create_and_link_note(selection)
                end
                return
              end
              local ok_note, note = pcall(function()
                return client:resolve_note(path, {
                  notes = { max_lines = client.opts.search_max_lines },
                })
              end)
              if not ok_note then
                vim.notify(string.format("Failed to resolve note from %s: %s", path, note), vim.log.levels.ERROR)
                return
              end
              if note then
                insert_link(note)
              else
                vim.notify(string.format("Could not resolve note for path %s", path), vim.log.levels.WARN)
              end
            end,
          })
        else
          local choice = vim.fn.confirm(
            string.format("Create new note for “%s”?", selection),
            "&Yes\n&No",
            1
          )
          if choice == 1 then
            insert_link(client:create_note { title = selection })
          else
            vim.notify(string.format("Skipped creating note for “%s”", selection), vim.log.levels.INFO)
          end
        end
      elseif #notes == 1 then
        insert_link(notes[1])
      else
        local picker = client:picker()
        if picker then
          picker:pick_note(notes, {
            prompt_title = string.format("Pick note for “%s”", selection),
            callback = function(note)
              insert_link(note)
            end,
          })
        else
          insert_link(notes[1])
        end
      end
    end)
  end)
end

-- ===================================================
-- Obsidian Commands (Global Keymaps)
-- ===================================================

-- Obsidian note management commands
keymap('n', '<leader>on', '<cmd>ObsidianNew<cr>', { desc = 'New note' })
keymap('n', '<leader>oo', '<cmd>ObsidianOpen<cr>', { desc = 'Open note' })
keymap('n', '<leader>os', '<cmd>ObsidianSearch<cr>', { desc = 'Search notes' })
keymap('n', '<leader>oq', '<cmd>ObsidianQuickSwitch<cr>', { desc = 'Quick switch' })
keymap('n', '<leader>of', '<cmd>ObsidianFollowLink<cr>', { desc = 'Follow link' })
keymap('n', '<leader>ob', '<cmd>ObsidianBacklinks<cr>', { desc = 'Show backlinks' })
keymap('n', '<leader>ot', '<cmd>ObsidianTags<cr>', { desc = 'View tags' })
keymap('n', '<leader>op', '<cmd>ObsidianPasteImg<cr>', { desc = 'Paste image' })
keymap('n', '<leader>om', '<cmd>ObsidianRename<cr>', { desc = 'Rename note' })
-- keymap('n', '<leader>om', '<cmd>ObsidianMove<cr>', { desc = 'Move note' })
keymap("v", "<leader>ol", link_or_create_obsidian_note, { desc = "Link or create Obsidian note" })
keymap('n', '<leader>od', '<cmd>bd | call delete(expand(\'%\'))<cr>', { desc = 'Delete note' })