return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "[C]ode [F]ormat with conform.nvim",
      },
    },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          c = { "clang_format" },
          css = { "prettierd", "prettier", stop_after_first = true },
          go = { "goimports", "gofmt" },
          html = { "prettierd", "prettier", stop_after_first = true },
          json = { "prettierd", "prettier", stop_after_first = true },
          jsonc = { "prettierd", "prettier", stop_after_first = true },
          lua = { "stylua" },
          markdown = { "prettierd", "prettier", stop_after_first = true },
          python = function(bufnr)
            if require("conform").get_formatter_info("ruff_format", bufnr).available then
              return { "ruff_format" }
            else
              return { "isort", "black" }
            end
          end,
          rust = { "rustfmt", lsp_format = "fallback" },
          scss = { "prettierd", "prettier", stop_after_first = true },
          terraform = { "terraform_fmt" },
          tf = { "terraform_fmt" },
          toml = { "taplo" },
          yaml = { "yamlfmt" },
          zig = { "zigfmt" },
        },
        format_on_save = {
          lsp_format = "fallback",
          timeout_ms = 500,
        },
        log_level = vim.log.levels.ERROR,
      })

      conform.formatters.rustfmt = {
        default_edition = "2024",
      }

      conform.formatters.taplo = {
        args = { "format", "--option", "indent_string=    ", "--option", "trailing_newline=false", "-" },
      }
    end,
  },
}
