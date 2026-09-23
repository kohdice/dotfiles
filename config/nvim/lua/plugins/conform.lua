return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          -- No lsp_format in caller opts: it would override every per-filetype
          -- lsp_format entry in formatters_by_ft
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
          proto = { "clang_format" },
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
          -- "prefer" over "fallback": trim_newlines always counts as
          -- available, so "fallback" would never reach the LSP (js/ts via tsc).
          ["_"] = { "trim_newlines", lsp_format = "prefer" },
        },
        -- Here rather than in the format() calls: caller opts outrank the
        -- per-filetype lsp_format entries above, these do not
        default_format_opts = {
          lsp_format = "fallback",
        },
        -- No lsp_format in the returned opts: it would override every
        -- per-filetype lsp_format entry in formatters_by_ft
        format_on_save = function(bufnr)
          if vim.g.enable_autoformat or vim.b[bufnr].enable_autoformat then
            return { timeout_ms = 500 }
          end
          return nil
        end,
        log_level = vim.log.levels.ERROR,
      })

      conform.formatters.taplo = {
        args = { "format", "--option", "indent_string=    ", "-" },
      }

      vim.api.nvim_create_user_command("FormatEnable", function(args)
        if args.bang then
          vim.b.enable_autoformat = true
        else
          vim.g.enable_autoformat = true
        end
      end, { desc = "Enable autoformat-on-save", bang = true })

      vim.api.nvim_create_user_command("FormatDisable", function()
        vim.b.enable_autoformat = false
        vim.g.enable_autoformat = false
      end, { desc = "Disable autoformat-on-save" })
    end,
  },
}
