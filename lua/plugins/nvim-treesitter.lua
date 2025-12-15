-- nvim-treesitter: Syntax highlighting and parsing
return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      -- Install parsers for common languages
      ensure_installed = {
        "lua",
        "vim",
        "bash",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "html",
        "css",
        "scss",
        "python",
        "java",
        "c",
        "cpp",
        "rust",
        "go",
        "php",
        "ruby",
        "swift",
        "kotlin",
        "scala",
        "clojure",
        "haskell",
        "ocaml",
        "fsharp",
        "elixir",
        "erlang",
        "scheme",
        "racket",
        "yaml",
        "toml",
        "dockerfile",
        "markdown",
        "r",
        "julia",
        "matlab",
        "sql",
        "graphql",
        "vue",
        "svelte",
        "astro",
      },
      -- Enable syntax highlighting
      highlight = {
        enable = true,
      },
      -- Enable indentation
      indent = {
        enable = true,
      },
    })
  end,
}

