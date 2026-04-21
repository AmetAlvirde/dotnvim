-- nvim-lspconfig: Core LSP configuration plugin
return {
  "neovim/nvim-lspconfig",
  lazy = false,
  dependencies = {
    "williamboman/mason.nvim",
  },
  config = function()
    -- Using modern vim.lsp.config API (Neovim 0.11+)
    
    -- LSP Keybindings (set up on LspAttach event)
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        local opts = { buffer = ev.buf }
        
        -- Navigation
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Go to declaration' }))
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Go to references' }))
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = 'Go to implementation' }))
        vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, vim.tbl_extend('force', opts, { desc = 'Go to type definition' }))
        
        -- Hover and signature help
        -- Note: K is already mapped by default to vim.lsp.buf.hover()
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
        vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature help' }))
        
        -- Code actions and refactoring
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code action' }))
        vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Code rename symbol' }))

        -- Formatting
        vim.keymap.set('n', '<leader>cf', function()
          vim.lsp.buf.format({ async = true })
        end, vim.tbl_extend('force', opts, { desc = 'Code format' }))

        -- Diagnostics navigation
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('force', opts, { desc = 'Diagnostic prev' }))
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('force', opts, { desc = 'Diagnostic next' }))
        vim.keymap.set('n', '<leader>dd', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = 'Diagnostic display' }))
        vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, vim.tbl_extend('force', opts, { desc = 'Diagnostic list' }))
      end,
    })
    
    -- Configure diagnostic signs and display
    local signs = {
      { name = "DiagnosticSignError", text = "✘" },
      { name = "DiagnosticSignWarn", text = "▲" },
      { name = "DiagnosticSignHint", text = "⚑" },
      { name = "DiagnosticSignInfo", text = "»" },
    }
    
    for _, sign in ipairs(signs) do
      vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
    end
    
    -- Configure diagnostic display
    vim.diagnostic.config({
      virtual_text = {
        prefix = '●',
        spacing = 4,
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
      },
    })
    
    -- Configure floating windows
    local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
    function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
      opts = opts or {}
      opts.border = opts.border or 'rounded'
      return orig_util_open_floating_preview(contents, syntax, opts, ...)
    end
    
    -- Configure ts_ls (TypeScript/JavaScript language server)
    vim.lsp.config('ts_ls', {
      cmd = { 'typescript-language-server', '--stdio' },
      filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
      root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
      settings = {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints = 'all',
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          },
        },
        javascript = {
          inlayHints = {
            includeInlayParameterNameHints = 'all',
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          },
        },
      },
    })
    
    -- Enable ts_ls
    vim.lsp.enable('ts_ls')
  end,
}

