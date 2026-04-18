return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
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
          cmake = { lsp_format = "prefer" },
          cpp = { "clang_format" },
          cuda = { lsp_format = "prefer" },
          css = { "prettierd", "prettier", stop_after_first = true },
          dockerfile = { lsp_format = "prefer" },
          go = { "goimports", "gofmt" },
          html = { "prettierd", "prettier", stop_after_first = true },
          json = { "prettierd", "prettier", stop_after_first = true },
          jsonc = { "prettierd", "prettier", stop_after_first = true },
          lua = { "stylua" },
          markdown = { "prettierd", "prettier", stop_after_first = true },
          objcpp = { lsp_format = "prefer" },
          proto = { lsp_format = "prefer" },
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
          ["_"] = { "trim_newlines" },
        },
        format_on_save = {
          lsp_format = "fallback",
          timeout_ms = 500,
        },
        log_level = vim.log.levels.ERROR,
      })

      conform.formatters.taplo = {
        args = { "format", "--option", "indent_string=    ", "-" },
      }
    end,
  },
}
