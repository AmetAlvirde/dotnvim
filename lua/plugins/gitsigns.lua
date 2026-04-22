-- gitsigns.nvim: Git signs/lines and integration (lightweight)
return {
  "lewis6991/gitsigns.nvim",
  lazy = false,
  config = function()
    require("gitsigns").setup({
      signs = {
        add          = { text = '│' },
        change       = { text = '│' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
      numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir = {
        follow_files = true
      },
      attach_to_untracked = true,
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
      },
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil, -- Use default
      max_file_length = 40000, -- Disable if file is longer than this (in lines of the length)
      preview_config = {
        -- Options passed to nvim_open_win
        border = 'rounded',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, {expr=true, desc = 'Next hunk'})

        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, {expr=true, desc = 'Previous hunk'})

        -- Actions
        map('n', '<leader>ghs', gs.stage_hunk, { desc = 'Git hunk stage' })
        map('n', '<leader>ghr', gs.reset_hunk, { desc = 'Git hunk reset' })
        map('v', '<leader>ghs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Git hunk stage' })
        map('v', '<leader>ghr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = 'Git hunk reset' })
        map('n', '<leader>ghS', gs.stage_buffer, { desc = 'Git hunk stage buffer' })
        map('n', '<leader>ghu', gs.undo_stage_hunk, { desc = 'Git hunk undo stage' })
        map('n', '<leader>ghR', gs.reset_buffer, { desc = 'Git hunk reset buffer' })
        map('n', '<leader>ghp', gs.preview_hunk, { desc = 'Git hunk preview' })
        map('n', '<leader>ghb', function() gs.blame_line{full=true} end, { desc = 'Git hunk blame line' })
        map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'Toggle blame' })
        map('n', '<leader>ghd', gs.diffthis, { desc = 'Git hunk diff' })
        map('n', '<leader>ghD', function() gs.diffthis('~') end, { desc = 'Git hunk diff ~' })
        map('n', '<leader>tx', gs.toggle_deleted, { desc = 'Toggle deleted' })

        -- Text object
        map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'Select hunk' })
      end
    })
  end,
}

