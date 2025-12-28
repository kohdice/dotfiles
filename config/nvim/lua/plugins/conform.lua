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
          go = { "goimports", "gofmt" },
          lua = { "stylua" },
          python = function(bufnr)
            if require("conform").get_formatter_info("ruff_format", bufnr).available then
              return { "ruff_format" }
            else
              return { "isort", "black" }
            end
          end,
          rust = { "rustfmt", lsp_format = "fallback" },
        },
        format_on_save = {
          lsp_format = "fallback",
          timeout_ms = 500,
        },
        format_after_save = {
          lsp_fallback = true,
        },
        log_level = vim.log.levels.ERROR,
      })

      conform.formatters.rustfmt = {
        default_edition = "2024",
      }
    end,
  },
}
