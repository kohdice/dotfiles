return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          -- lsp_format is deliberately not passed here: caller opts are kept
          -- as-is by conform, which would override every per-filetype
          -- lsp_format. It lives in default_format_opts instead.
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
          -- Catch-all for filetypes with no entry above. "fallback" would
          -- never fire for them: trim_newlines needs no external command, so
          -- conform always counts a formatter as available. "prefer" hands
          -- them to the LSP when one supports formatting (js/ts via tsgo, ...)
          -- and falls back to trim_newlines when none does.
          ["_"] = { "trim_newlines", lsp_format = "prefer" },
        },
        -- Merged after the per-filetype opts above, which therefore win.
        -- Passing lsp_format from the caller (format_on_save or the keymap)
        -- instead would take precedence over every filetype entry, because
        -- conform only fills in opts the caller left unset.
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
