-- conform.nvim: Advanced code formatting
return {
  "stevearc/conform.nvim",
  lazy = false,
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier-markdown" },
        python = { "black", "isort" },
        go = { "gofmt", "goimports" },
        rust = { "rustfmt" },
        yaml = { "prettier" },
        toml = { "taplo" },
        sh = { "shfmt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters = {
        prettier = {
          prepend_args = { "--print-width", "80", "--tab-width", "2" },
        },
        ["prettier-markdown"] = {
          command = "prettier",
          args = { "--stdin-filepath", "$FILENAME", "--print-width", "80", "--tab-width", "2", "--prose-wrap", "always" },
        },
        black = {
          prepend_args = { "--line-length", "80" },
        },
        stylua = {
          prepend_args = { "--column-width", "80" },
        },
      },
    })
  end,
}

