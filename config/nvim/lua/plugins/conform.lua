return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          -- No lsp_format here: caller opts would override every per-filetype
          -- one. See default_format_opts below.
          require("conform").format({ async = true })
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
          -- Catch-all. "prefer" over "fallback": trim_newlines always counts as
          -- available, so "fallback" would never reach the LSP (js/ts via tsc).
          ["_"] = { "trim_newlines", lsp_format = "prefer" },
        },
        -- Here rather than at the call sites: caller opts outrank the
        -- per-filetype lsp_format above, these do not.
        default_format_opts = {
          lsp_format = "fallback",
        },
        format_on_save = {
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
