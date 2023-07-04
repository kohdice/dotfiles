return {
  'jose-elias-alvarez/null-ls.nvim',
  event = 'VeryLazy',
  dependencies = {
    'williamboman/mason.nvim',
    'jay-babu/mason-null-ls.nvim',
  },
  config = function()
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    local lsp_formatting = function(bufnr)
      vim.lsp.buf.format({
        filter = function(client)
          return client.name == "null-ls"
        end,
        bufnr = bufnr,
      })
    end

    require("mason").setup()
    local null_ls = require('null-ls')
    null_ls.setup {
      sources = {
        -- Python
        null_ls.builtins.formatting.black.with {
          extra_args = { "--fast" },
          prefer_local = ".venv/bin"
        },
        null_ls.builtins.formatting.isort.with {
          prefer_local = ".venv/bin"
        },
        null_ls.builtins.diagnostics.flake8.with {
          prefer_local = ".venv/bin"
        },
        null_ls.builtins.diagnostics.mypy.with {
          prefer_local = ".venv/bin"
        },
        -- Go
        null_ls.builtins.formatting.gofmt,
        null_ls.builtins.diagnostics.golangci_lint,
        -- Typescript・Javascript
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.diagnostics.eslint_d.with({
          diagnostics_format = '[eslint] #{m}\n(#{c})'
        }),
        -- fish
        null_ls.builtins.diagnostics.fish,
        -- sql
        null_ls.builtins.formatting.sqlfmt.with {
          prefer_local = ".venv/bin"
        }
      },
      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              lsp_formatting(bufnr)
            end,
          })
        end
      end
    }
    require("mason-null-ls").setup({
        ensure_installed = nil,
        automatic_installation = true,
    })

    vim.api.nvim_create_user_command(
      'DisableLspFormatting',
      function()
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = 0 })
      end,
      { nargs = 0 }
    )
  end
}
