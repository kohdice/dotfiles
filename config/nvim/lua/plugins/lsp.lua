return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "folke/neodev.nvim" },
    config = function()
      require("neodev").setup()

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if has_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("my-lsp-attach", { clear = true }),
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          local bufnr = args.buf

          -- Set up keymaps
          local nmap = function(keys, func, desc)
            if desc then
              desc = "LSP: " .. desc
            end
            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
          end

          nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
          nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
          nmap("gr", "<cmd>FzfLua lsp_references<cr>", "[G]oto [R]eferences")
          nmap("gt", vim.lsp.buf.type_definition, "[G]oto [T]ype Definition")
          nmap("gds", "<cmd>FzfLua lsp_document_symbols<cr>", "[D]ocument [S]ymbols")
          nmap("gws", "<cmd>FzfLua lsp_workspace_symbols<cr>", "[W]orkspace [S]ymbols")

          nmap("gK", vim.lsp.buf.signature_help, "Signature Documentation")

          nmap("<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, "[F]ormat")

          -- C/C++ specific keymaps
          if client.name == "clangd" then
            nmap("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header (C/C++)")
          end

          vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
            vim.lsp.buf.format()
          end, { desc = "Format current buffer with LSP" })
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = bufnr,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = bufnr,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      local servers = {
        "clangd",
        "cssls",
        "dockerls",
        "emmet_ls",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        "marksman",
        "neocmake",
        "rust_analyzer",
        "taplo",
        "terraformls",
        "ts_ls",
        "yamlls",
        "zls",
      }
      vim.lsp.enable(servers)
    end,
  },
}
